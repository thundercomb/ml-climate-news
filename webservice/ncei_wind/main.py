from flask import Flask

import requests as rq
import logging
import os
import time
import datetime
import csv
from random import randint

from google.cloud import pubsub_v1
from google.cloud import bigquery


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

    response = rq.get(url)
    lines = response.text.splitlines()

    chunk_size = 50

    print('Publishing data to {} ...'.format(topic_path))
    count = 0
    chunk = []
    for line in lines[1:]:
        if count < chunk_size:
            chunk.append(line)
            count += 1
        if count == chunk_size:
            bytes_chunk = bytes("\r\n".join(chunk).encode('utf-8'))
            publisher.publish(topic_path, data=bytes_chunk)
            chunk = []
            count = 0
    if count > 0:
        bytes_chunk = bytes("\r\n".join(chunk).encode('utf-8'))
        publisher.publish(topic_path, data=bytes_chunk)

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
    if message.data:
        decoded_message = message.data.decode('utf-8')
        lines = decoded_message.splitlines()
        rows_to_insert = []

        for line in lines:
            reader = csv.reader([line])
            for row in reader:
                d = datetime.datetime.strptime(row[1],'%Y-%m-%dT%H:%M:%S')
                row[1] = d.strftime('%Y-%m-%d %H:%M:%S')

                tuple_row = tuple(row)
                rows_to_insert.append(tuple_row)

        errors = bq_client.insert_rows(table, rows_to_insert)
        if errors != []:
            print(errors)
        else:
            message.ack()

    assert errors == []

def create_table():
    schema = [
        bigquery.SchemaField("Station", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("Date", "DATETIME", mode="NULLABLE"),
        bigquery.SchemaField("Latitude", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("Longitude", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("Wind_Dir", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("Wind_Speed", "STRING", mode="NULLABLE"),
    ]

    table = bigquery.Table(table_id, schema=schema)
    table = bq_client.create_table(table)  # API request
    print(
        "Created table {}.{}.{}".format(table.project, table.dataset_id, table.table_id)
    )

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
table = bq_client.get_table(table_ref)
