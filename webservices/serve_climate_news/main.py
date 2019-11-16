from flask import Flask
from google.cloud import storage
import gpt_2_simple as gpt2

import os
from google.cloud.exceptions import NotFound, Conflict


app = Flask(__name__)

@app.route('/')
def home():
    article = gpt2.generate(sess)
    return render_template('home.html', article=article)

@app.errorhandler(500)
def server_error(e):
    print('An internal error occurred')
    return 'An internal error occurred.', 500

print("Loading gpt2 session..")
sess = gpt2.start_tf_sess()
gpt2.load_gpt2(sess)

print("Ready to serve.")
