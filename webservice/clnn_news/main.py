from flask import Flask

import requests as rq
import logging
import os
import math
import time
import datetime
import csv
from random import randint
import feedparser
from bs4 import BeautifulSoup

from google.cloud import pubsub_v1
from google.cloud import bigquery
from google.cloud.exceptions import NotFound, Conflict


app = Flask(__name__)

@app.route('/')
def ok():
    return 'ok'

@app.route('/ingest')
def ingest():
    topic_name = os.getenv('TOPIC')
    url = os.getenv('URL')

    publisher = pubsub_v1.PublisherClient(batch_settings=pubsub_v1.types.BatchSettings(max_latency=5))
    topic_path = publisher.topic_path(project_id, topic_name)

    feed = feedparser.parse(url)

    pages = []
    today_date = f"{datetime.datetime.now():%Y-%m-%d}"
    for post in feed.entries:
        post_date = "%d-%02d-%02d" % (post.published_parsed.tm_year,\
            post.published_parsed.tm_mon, \
            post.published_parsed.tm_mday)
        #if post_date == today_date:
        if post_date:
            print("post date: " + post_date)
            print("post title: " + post.title)
            print("post link: " + post.link)
            page = rq.get(post.link).text
            pages.append(page)

    chunk_size = 50
    count = 0
    message_count = 0
    chunk = []

    print('Publishing data to {} ...'.format(topic_path))
    for page in pages:
        text = ""
        flag = 0
        soup = BeautifulSoup(page, "lxml")
        for s in soup.findAll('p'):
            if '<em>− Climate News Network</em>' in str(s):
                text = text + s.text.encode("utf-8").decode("utf-8").replace('− Climate News Network','') + "\n"
                flag = 1
            elif not '<p><' in str(s) and flag == 0:
                text = text + s.text.encode("utf-8").decode("utf-8") + "\n"

        if count < chunk_size:
            chunk.append(text)
            count += 1
        if count == chunk_size:
            bytes_chunk = bytes("@@".join(chunk).encode('utf-8'))
            publisher.publish(topic_path, data=bytes_chunk)
            chunk = []
            count = 0
            message_count = message_count + 1

    if count > 0:
        bytes_chunk = bytes("@@".join(chunk).encode('utf-8'))
        publisher.publish(topic_path, data=bytes_chunk)

    print('Published {} rows in {} messages'.format((message_count * chunk_size) + count, message_count + math.ceil(count/chunk_size)))

    subscribe()

    return 'ok'

def subscribe():
    future = subscriber.subscribe(subscription_path, callback=callback)

    # The subscriber is non-blocking, so we must keep the main thread from
    # exiting to allow it to process messages in the background.
    print('Listening for messages on {} ...'.format(subscription_path))
    loop = True
    while loop:
        response = subscriber.pull(subscription_path, 10)
        if len(response.received_messages) > 0:
            time.sleep(1)
        else:
            print('No more messages, canceling subscription...')

            future.cancel()
            loop = False
            return

def callback(message):
    errors = []

    if message.data:
        decoded_message = message.data.decode('utf-8')
        lines = decoded_message.split('@@')
        rows_to_insert = []

        for line in lines:
            tuple_row = tuple([line])
            rows_to_insert.append(tuple_row)

        try:
            table = bq_client.get_table(table_ref)
        except NotFound:
            create_table()
            table = bq_client.get_table(table_ref)

        print("Inserting {} rows into BigQuery ...".format(len(rows_to_insert)))

        print(rows_to_insert)
        errors = bq_client.insert_rows(table, rows_to_insert)
        if errors != []:
            print(errors)
        else:
            message.ack()

    assert errors == []

def create_table():
    schema = [
        bigquery.SchemaField("Article", "STRING", mode="NULLABLE"),
    ]

    table = bigquery.Table(table_ref, schema=schema)
    try:
        bq_client.get_table(table)
    except NotFound:
        try:
            table = bq_client.create_table(table)
            print("Created table {}.{}.{}".format(table.project, table.dataset_id, table.table_id))
            print("Going to sleep for 60 seconds to ensure data availability in newly created table")
            time.sleep(60)
        except Conflict:
            pass

    return

@app.errorhandler(500)
def server_error(e):
    print('An internal error occurred')
    return 'An internal error occurred.', 500

print("Preparing..")
project_id = os.getenv('PROJECT')
subscription_name = os.getenv('SUBSCRIPTION')

subscriber = pubsub_v1.SubscriberClient()
subscription_path = subscriber.subscription_path(project_id, subscription_name)

dataset_id = os.getenv('DATASET')
table_id = os.getenv('TABLE')

bq_client = bigquery.Client()
table_ref = bq_client.dataset(dataset_id).table(table_id)
