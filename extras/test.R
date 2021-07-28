library(quanteda)
library(dplyr)
library(magrittr)
intensifyers = read.table('lijst_intrinsieke_intensiveerders.txt', stringsAsFactors=F)

negatives = read.csv2('polarityLexiconDutchVU.txt', header = F, col.names = c("word", "type", "posneg"), stringsAsFactors=F)
negatives = negatives %>%
  filter(posneg == 'negative') %>%
  select(word)

sent_dict = dictionary(list(intensity = intensifyers$V1, negativity = negatives$word))
