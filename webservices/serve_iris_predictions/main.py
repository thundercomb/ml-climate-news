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
    global model

    print("Loading model..")
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(source_blob_name)
    if blob.exists():
        f = io.BytesIO()
        blob.download_to_file(f)
        model = load(f)
    else:
        model = None

    print("Making predictions..")
    results = model.predict(X)
    return str(results)

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

print("Creating checkpoint directory..")
if not os.path.exists(checkpoint_dir):
    os.makedirs(checkpoint_dir)
    print("Downloading model..")
    download_blob(bucket_name, source_blob_name, destination_file_name)

print("Ready to serve.")
