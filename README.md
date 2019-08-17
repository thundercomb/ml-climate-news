# Purpose

Analytics platform for climate change data

# Prerequisites

terraform 0.12
gcloud

# Install

git clone https://github.com/thundercomb/gcp-climate-analytics
cd gcp-climate-analytics
bash start.sh

# Run webservice

Navigate to

`http://ncei-wind-dot-<my-project-id>.appspot.com/`

The web page should receive 'ok'

Now ingest data by sending a request with

`http://ncei-wind-dot-<my-project-id>.appspot.com/ingest`

The example data is now in a BigQuery table called `wind` in dataset `ncei`

# Troubleshooting

## Failed start script

## Failed web service

If the web service does not come up, go to the App Engine dashboard and look for the relevant service. It should be running. Look at the logs for clues as to why it might be failing.
