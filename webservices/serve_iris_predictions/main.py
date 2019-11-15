from flask import Flask, render_template
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
        message = "Please download model first"
        return render_template('message.html', message=message)
    else:
        global model

        print("Loading model..")
        model = load(destination_file_name)

        print("Making predictions..")
        predictions = f"{model.predict(X)}"
        real_targets = f"{y}"
        return render_template('home.html', predictions=predictions, real_targets=real_targets)

@app.route('/download')
def download():
    print("Creating checkpoint directory if required..")
    if not os.path.exists(checkpoint_dir):
        os.makedirs(checkpoint_dir)
    if os.path.exists(destination_file_name):
        print("Removing old model..")
        os.remove(destination_file_name)

    print("Finding model to download..")
    blob_names = list_blobs(bucket_name, bucket_prefix)

    model_to_download = ""
    for blob in blob_names:
        if model_version == "latest":
            if blob.name.find(".latest", -8) > 0:
                model_to_download = blob.name
        else:
            if blob.name.find(model_version) > 0:
                model_to_download = blob.name

    if model_to_download == "":
        message = f"Could not find model '{model_latest}' in bucket {bucket_name}"
        return render_template('message.html', message=message)
    else:
        print("Downloading model..")
        download_blob(bucket_name, model_to_download, destination_file_name)

        print("Ready to serve.")

        message = f"Downloaded model {model_to_download}, ready to serve"
        return render_template('message.html', message=message)

def download_blob(bucket_name, source_blob_name, destination_file_name):
    """Downloads a blob from the bucket."""
    storage_client = storage.Client()
    bucket = storage_client.get_bucket(bucket_name)
    blob = bucket.blob(source_blob_name)

    blob.download_to_filename(destination_file_name)

    print('Blob {} downloaded to {}.'.format(
        source_blob_name,
        destination_file_name))

def list_blobs(bucket_name, prefix):
    """Lists all the blobs in the bucket."""
    storage_client = storage.Client()

    # Note: Client.list_blobs requires at least package version 1.17.0.
    blobs = storage_client.list_blobs(bucket_name, prefix=prefix)

    return blobs

@app.errorhandler(500)
def server_error(e):
    print('An internal error occurred')
    return 'An internal error occurred.', 500

print("Preparing..")
project_id = os.getenv('PROJECT')
bucket_name = os.getenv('ML_MODELS_BUCKET')
bucket_prefix = os.getenv('BUCKET_PREFIX')
model_version = os.getenv('MODEL_VERSION')
model_name = os.getenv('MODEL_NAME')
checkpoint_dir = '/tmp/checkpoint'
destination_file_name = f"{checkpoint_dir}/{model_name}"

print("Downloading iris dataset..")
iris = datasets.load_iris()
X, y = iris.data, iris.target
print("Ready")
