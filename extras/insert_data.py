from elasticsearch import Elasticsearch
es = Elasticsearch('http://localhost:9200')

import json, sys

index = 'test'

fn = sys.argv[1]
with open(fn) as f:
    articles = json.load(f)


print(f"Inserting {len(articles)} into index {index}")

for article in articles:
    print(repr(article["title"]))
    es.index(index=index, doc_type="article",
             id = article["id"],
             body=article)
