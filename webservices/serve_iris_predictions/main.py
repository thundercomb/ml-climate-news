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
    print("Making predictions..")
    predictions = f"{model.predict(X)}"
    real_targets = f"{y}"
    return render_template('home.html', predictions=predictions, real_targets=real_targets)

@app.errorhandler(500)
def server_error(e):
    print('An internal error occurred')
    return 'An internal error occurred.', 500

print("Preparing..")
model_name = os.getenv('MODEL_NAME')

print("Downloading iris dataset..")
iris = datasets.load_iris()
X, y = iris.data, iris.target

print("Loading model..")
model = load(model_name)

print("Ready to serve.")
