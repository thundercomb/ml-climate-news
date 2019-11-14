from flask import Flask
from google.cloud import storage
import gpt_2_simple as gpt2

import shutil
import os
from google.cloud.exceptions import NotFound, Conflict


app = Flask(__name__)

@app.route('/')
def home():
    results = gpt2.generate(sess)
    return results

def download_blob(bucket_name, source_blob_name, destination_file_name):
    """Downloads a blob from the bucket."""
    storage_client = storage.Client()
    bucket = storage_client.get_bucket(bucket_name)
    blob = bucket.blob(source_blob_name)

    blob.download_to_filename(destination_file_name)

    print('Blob {} downloaded to {}.'.format(
        source_blob_name,
        destination_file_name))

@app.errorhandler(500)
def server_error(e):
    print('An internal error occurred')
    return 'An internal error occurred.', 500

print("Preparing..")
project_id = os.getenv('PROJECT')
bucket_name = os.getenv('ML_MODELS_BUCKET')
source_blob_name = os.getenv('MODEL_ARCHIVE')
destination_file_name = 'checkpoint/' + source_blob_name

print("Creating checkpoint directory..")
if not os.path.exists('checkpoint'):
    os.makedirs('checkpoint')

print("Downloading model..")
download_blob(bucket_name, source_blob_name, destination_file_name)

print("Load gpt2 session..")
sess = gpt2.start_tf_sess()
gpt2.load_gpt2(sess)

print("Ready to serve.")
