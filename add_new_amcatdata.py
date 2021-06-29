from amcatclient import AmcatAPI
from elasticsearch import Elasticsearch

amcat = AmcatAPI("https://vu.amcat.nl", "nickmattis", "Nimima&95blabla")
es = Elasticsearch()

es.indices.create("inca")

for article in amcat.get_articles(project=69, articleset=2564, start_date="2021-03-09", columns=("date", "title", "publisher", "url", "text", "author", "section")):
    es.create(index="inca", id=article['id'], body=article)

