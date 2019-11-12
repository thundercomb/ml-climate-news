import gpt_2_simple as gpt2
from google.cloud import bigquery

client = bigquery.Client()

query = (
    "SELECT article FROM `climate-poc-01.clnn.news`"
)
query_job = client.query(
    query,
)

articles = ""
for row in query_job:
    articles = articles + row.article

textfile = open('clnn.txt', 'w')
textfile.write(articles)
textfile.close()

model_name = "124M"
gpt2.download_gpt2(model_name=model_name)   # model is saved into current directory under /models/124M/

sess = gpt2.start_tf_sess()
gpt2.finetune(sess,
              'clnn.txt',
              model_name=model_name,
              steps=5)   # steps is max number of training steps

gpt2.generate(sess)
