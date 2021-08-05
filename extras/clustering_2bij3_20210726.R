library(amcatr)
library(tidyverse)
library(dplyr)
library(quanteda)
library(quanteda.textstats)
library(jsonlite)
library(data.table)
library(stringr)

## First, set the date for article retrieval. For automation purposes, this is set to 
## find the system date. It can be manually set to any date in "yyyy-mm-dd" format.
scrape_date = Sys.Date()-1

## Connect to amcat using personal credentials.
conn = amcat.connect("https://vu.amcat.nl")

## Since amcat.getobjects() wasn't working, this pulls all articles in project 2, articleset 1340, then filters for
## only today's articles, dropping duplicates.

filters = toJSON(list(start_date=unbox(scrape_date)))
print("Getting data from AmCAT project 2 set 1340")
d_amcat = amcat.articles(conn, project=2, articleset=1340, columns=c("date", "title","publisher","url", "text"), filters=filters)
# d_amcat_today = filter(d_amcat, date == scrape_date & sapply(strsplit(d_amcat$title, " "), length) > 2)
d_amcat_today = d_amcat[!duplicated(d_amcat$title),]

## Create a corpus from the article titles, tokenize this and create a dfm weighted by tf-idf.
c_amcat = corpus(d_amcat_today, text_field="text")
tokenized_amcat = tokens(c_amcat, remove_punct = T)
dfm_amcat = dfm(tokenized_amcat)
dfm_amcat_weighted = dfm_tfidf(dfm_amcat, scheme_tf = "prop")

## Compute the similarity between titles using cosine similarity, discard all similarities under
## 0.4 (as recommended by Trilling & van Hoof, 2020).
amcat_simil = textstat_simil(dfm_amcat_weighted, margin='documents', method = 'cosine')
df_amcat_simil = as.data.frame(as.matrix(amcat_simil))
df_amcat_simil[df_amcat_simil<0.4]=0
df_amcat_simil_test = df_amcat_simil


secondmax = c()
for(i in 1:nrow(df_amcat_simil_test)) {
  x <- df_amcat_simil_test[i,]
  secondmax = append(secondmax, max(x[x != max(x)]))
}

df_amcat_simil$secondmax <- c(secondmax)
df_amcat_simil[df_amcat_simil<df_amcat_simil$secondmax]=0

## Create a dataframe of similar texts for each title, to get the required output format.
df_clustered = as.data.frame(matrix(nrow = length(df_amcat_simil$text1), ncol = 1))
rownames(df_clustered) = rownames(df_amcat_simil)
colnames(df_clustered) = c("similar_texts")

for(i in 1:length(df_clustered$similar_texts)){
  simil_list = c()
  for(j in 1:length(df_clustered$similar_texts)){
    if(is.na(df_amcat_simil[i, j])) {
      next
    } else if(df_amcat_simil[i,j] >= 0.4 & df_amcat_simil[i,j] <1){
      simil_list = append(simil_list, colnames(df_amcat_simil)[j])
    } else {
      next
    }
    if(is.null(simil_list)){
      next
    } else {
      df_clustered$similar_texts[i] = list(simil_list)
    }
  }
}

df_clustered = filter(df_clustered, !is.na(similar_texts))

## Add two columns to the amcat dataframe for intensity and negativity, respectively.
## Base these columns on word lists

intensifyers = read.table('lijst_intrinsieke_intensiveerders.txt', stringsAsFactors=F)

negatives = read.csv2('polarityLexiconDutchVU.txt', header = F, col.names = c("word", "type", "posneg"), stringsAsFactors=F)
negatives = negatives %>%
  filter(posneg == 'negative') %>%
  select(word)

sent_dict = dictionary(list(intensity = intensifyers$V1, negativity = negatives$word))
c_titles = corpus(d_amcat_today, text_field="title")
tokenized_titles = tokens(c_titles, remove_punct = T)
dfm_titles = dfm(tokenized_titles)

dict_dfm = dfm_lookup(dfm_titles, sent_dict)
df_sent = as.data.frame(as.matrix(dict_dfm))

## Merge the clustered dataframe with the intensity/negativity dataframe and put everything in the right format.
setDT(df_clustered, keep.rownames='titles')
setDT(df_sent, keep.rownames='titles')
df_texts = d_amcat_today %>%
  select(text = title) %>%
  rownames_to_column(var="titles")
df_texts$titles = paste0("text", df_texts$titles)

df_output = merge(df_clustered, df_sent)
df_output = merge(df_output, df_texts)
df_output = df_output %>%
  unnest(cols=c(similar_texts)) %>%
  filter(titles != similar_texts & similar_texts %in% titles)
df_output[,"cluster_id"] = NA

id_list = c()
cluster_no = 0
for(i in 1:length(df_output$titles)) {
  if(!(df_output$titles[i] %in% id_list) & !(df_output$similar_texts[i] %in% id_list)){
    cluster_no = cluster_no + 1
    df_output$cluster_id[i] = cluster_no
    df_output$cluster_id[df_output$titles %in% df_output$similar_texts[i]] = cluster_no
    id_list = append(id_list, c(df_output$titles[i], df_output$similar_texts[i]))
  } else if((df_output$titles[i] %in% id_list) & !(df_output$similar_texts[i] %in% id_list)){
    df_output$cluster_id[i] = cluster_no
    id_list = append(id_list, df_output$similar_texts[i])
  } else if((df_output$titles[i] %in% id_list) & (df_output$similar_texts[i] %in% id_list)){
    temp_cluster_list =  df_output$cluster_id[df_output$similar_texts %in% df_output$titles[i]]
    df_output$cluster_id[i] = temp_cluster_list[1]
  }
    else{
    next
  }
}
df_output = df_output %>%
  filter(!is.na(cluster_id)) %>%
  nest(similar_texts = similar_texts)

for (i in 1:length(df_output$similar_texts)) {
  x = as.data.frame(df_output$similar_texts[i])
  df_output$similar_texts[i] = list(x[,1])
}

df_output = merge(df_output, d_amcat_today, by.x = "text", by.y = 'title')

df_output = df_output %>%
  select(publisher, date, url, title = text, text = text.y, intensity, negativity, cluster_id, similar_texts) %>%
  add_rownames(var = "id") %>%
  add_column(section = NA)

## Write the final dataframe to a json file for use in 2bij3
j_2bij3 = toJSON(df_output, auto_unbox = T)
#cat(j_2bij3)
write(j_2bij3, file = "clustered_for_3bij2.json")

#backup
save_date = scrape_date+1
filename = paste(save_date,"_clustered_for_3bij2.json",sep="")
filename = gsub(":","-",filename)
write(j_2bij3, file = filename)
