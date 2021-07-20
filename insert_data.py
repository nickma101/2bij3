from elasticsearch import Elasticsearch
es = Elasticsearch('http://localhost:9200')

import json

f = open('test.json', orient='index')
articles = f.read()

es.index(index="test", ignore=400, doc_type="articles", id=1, body=json.dumps(articles))


    def negative_articles2(self, by_field = "META.ADDED", num = None):
        df = pd.read_json("clustered_for_3bij2.json", encoding='latin-1')
        #negative article list
        neg_articles = df.loc[df['negativity'] > 0]
        #neutral article lest
        neu_articles = df.loc[df['negativity'] == 0]
        #seperate list for those articles that have neutral article in the same cluster
        neg_articles["useful"] = neg_articles["cluster_id"].isin(neu_articles["cluster_id"])
        neg_articles_useful = neg_articles.loc[neg_articles['useful'] == True]
        neg_articles_useful
        
        #intense article list
        intense_articles = df.loc[df['intensity'] > 0]
        #non-intense article lest
        boring_articles = df.loc[df['intensity'] == 0]
        #seperate list for those articles that have neutral article in the same cluster
        intense_articles["useful"] = intense_articles["cluster_id"].isin(boring_articles["cluster_id"])
        intense_articles_useful = intense_articles.loc[intense_articles['useful'] == True]
        intense_articles_useful
        
        def intense_condition(df_intense, df_neu):
            article1 = df_intense.sample()
            article2 = df_neu.loc[df_neu["cluster_id"].isin(article1["cluster_id"])].sample()
            return article1.append(article2)

        def negative_condition(df_neg, df_neu):
            article1 = df_neg.sample()
            article2 = df_neu.loc[df_neu["cluster_id"].isin(article1["cluster_id"])].sample()
            return article1.append(article2)
		
        negative = negative_condition(neg_articles_useful, neu_articles)
        intense = intense_condition(intense_articles_useful, boring_articles)

        results = []
        for article in negative:
            results.append(article)
        for article in intense:
            results.append(article)
