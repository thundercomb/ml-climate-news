from flask import Flask, render_template
from google.cloud import storage

import os
import datetime
from google.cloud.exceptions import NotFound, Conflict

def list_blobs(bucket_name, prefix):
    """Lists all the blobs in the bucket."""
    # Note: Client.list_blobs requires at least package version 1.17.0.
    blobs = storage_client.list_blobs(bucket_name, prefix=prefix)

    return blobs

app = Flask(__name__)

@app.route('/')
def home():
    article = "<BR/><BR/>".join(articles)
    return render_template('home.html', article=article)

@app.errorhandler(500)
def server_error(e):
    print('An internal error occurred')
    return 'An internal error occurred.', 500

storage_client = storage.Client()
articles = []

ml_articles_bucket = os.getenv('ML_ARTICLES_BUCKET')
blobs = list_blobs(ml_articles_bucket,'news')
for blob in blobs:
    blob_datetime_str = f"{blob.name.split('_')[1]}_{blob.name.split('_')[2].split('.')[0]}"
    dt_obj = datetime.datetime.strptime(blob_datetime_str,'%Y%m%d_%H%M%S')
    article_datetime_str = datetime.datetime.strftime(dt_obj,"News at %H:%M on %A, %d %B %Y")

    article_text = blob.download_as_string().decode('utf-8')
    article_text_trim = article_text[0:article_text.rfind(.)]
    article_doc = f"<b>{article_datetime_str}</b><BR/><BR/>{article_text_trim}"
    articles.append(article_doc)

print("Ready to serve.")
