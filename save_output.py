import csv
from app import db
from app.models import News_sel

def sql_query_to_csv(query_output, columns_to_exclude=""):
     rows = query_output
     columns_to_exclude = set(columns_to_exclude)
     column_names = [i for i in rows[0].__dict__]
     for column_name in columns_to_exclude:
         column_names.pop(column_names.index(column_name))
     column_names.sort()
     csv = ", ".join(column_names) + "\n"
     for row in rows:
         for column_name in column_names:
             if column_name not in columns_to_exclude:
                 data = str(row.__dict__[column_name])
                 data.replace('"','""')
                 csv += '"' + data + '"' + ","
         csv += "\n"
     return csv
 
query = News_sel.query.all()
csv1 = sql_query_to_csv(query)

print(csv1)
