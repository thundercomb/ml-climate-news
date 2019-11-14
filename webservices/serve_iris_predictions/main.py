from flask import Flask
from google.cloud import storage
from sklearn import datasets
from joblib import load

import shutil
import os
import io
from google.cloud.exceptions import NotFound, Conflict


app = Flask(__name__)

@app.route('/')
def home():
    if not os.path.exists(destination_file_name):
        return "Please download model: /download"
    else:
        global model

        print("Loading model..")
        model = load(destination_file_name)

        print("Making predictions..")
        results = model.predict(X)
        return str(results)

@app.route('/download')
def download():
    print("Creating checkpoint directory if required..")
    if not os.path.exists(checkpoint_dir):
        os.makedirs(checkpoint_dir)
    if os.path.exists(destination_file_name):
        print("Removing old model..")
        os.remove(destination_file_name)

    print("Downloading model..")
    download_blob(bucket_name, source_blob_name, destination_file_name)

    print("Ready to serve.")

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
source_blob_name = os.getenv('MODEL')
checkpoint_dir = '/tmp/checkpoint/'
destination_file_name = checkpoint_dir + source_blob_name

print("Downloading iris dataset..")
iris = datasets.load_iris()
X, y = iris.data, iris.target