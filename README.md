# Purpose

ML Climate News is an end-to-end machine learning platform serving climate fake news.  
Sadly, this proves that it is easier than ever to spread disinformation!

To learn about the real science of Climate Change:

[Royal Society: Climate Change Basics](https://royalsociety.org/topics-policy/projects/climate-change-evidence-causes/basics-of-climate-change/)  
[NASA: Evidence of Global Climate Change](https://climate.nasa.gov/evidence/)  
[IPCC: Climate Change report 2013](https://www.ipcc.ch/report/ar5/wg1/)  
[Science Net Links: The Science of Climate Change](http://sciencenetlinks.com/collections/climate-change/)  

# Prerequisites

## Tooling

* terraform 0.12
* gcloud
* gsutil

## Set up

* gcp account with billing enabled
* gcloud login
* `terraform.tfvars` file with settings based on `terraform.tfvars.example` template

# Install

```
git clone https://github.com/thundercomb/gcp-climate-analytics
cd gcp-climate-analytics
bash start.sh
```

This process takes several minutes. You should eventually see the following messages:

```
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
```

This means the Kubeflow frontend is now available. Navigate to `http://localhost:8080`.

# How it works

The Climate News ML platform is a fully fledged end-to-end machine learning platform.
The simplest way to think of the process is as follows:

*Ingestion -> Data -> Machine Learning -> Models -> Serving*

## Ingestion

Machine Learning models rely on data. The Google App Engine ingestion services first ingest data and then insert the data into BigQuery tables.

There are currently two ingestion services: ncei and clnn. As the platform matures, more data sources will be added.

The ingestion can be run as a one-off as follows.

Navigate to

`https://ncei-wind-dot-<my-project-id>.appspot.com/`

The web page should receive 'ok'

Now ingest data by sending a request with

`https://ncei-wind-dot-<my-project-id>.appspot.com/ingest`

The example data is now in a BigQuery table called `wind` in dataset `ncei`

To see all of the available ingestion services, navigate to App Engine on the console:

`https://console.cloud.google.com/appengine/services?project=<your-project-id>`

Or use gcloud:

`gcloud app services list --project=<your-project-id>`

All services starting `ingest-` are ingestion services.

## Data

By default ingestion data is stored in BigQuery. Sources are logically separated by datasets rather than by table, to permit fine-grained control over ACLs.

## Machine Learning

Machine Learning requires a platform on which to run experiments and save models that make the cut. Kubeflow provides a number of capabilities through Katib experiments, Argo workflows, and Kubeflow pipelines.

The current process is still immature. We use a simple Argo workflow, which can be uploaded via the Kubeflow dashboad, to train a model and save it as a versioned artefact on GCS.

The iris dataset is used as an example to test the workflow for the real process, which finetunes OpenAI's [GPT-2](https://openai.com/blog/better-language-models/) using Minimaxir's (gpt_2_simple)[https://github.com/minimaxir/gpt-2-simple] library.

Current limitations are in artefact passing when using Argo. The training script manages it, whereas this should be externalised to the pipeline config.

## Models

The models are stored in prefixed directories on GCS. Kubeflow provides [Minio](https://min.io/), which is another option.

## Serving

The serving web services use the trained and finetuned models to generate information and present it to users. The serving web services run on Google App Engine. The iris sample web service is stable.

As with the ingestion services, navigate to

`https://serve-iris-predictions-dot-<my-project-id>.appspot.com/`

This should tell you to first download the model.

`https://serve-iris-predictions-dot-<my-project-id>.appspot.com/download`

Once downloaded, the home endpoint will serve the predictions.

# DevOps and MLOps

The platform provides the building blocks to manage code and ml model artefacts according to DevOps and MLOps principles.

Cloud Build CI pipelines build ML images and push them to Google's Container Registry (gcr.io).
Cloud Build CD pipelines deploys code repos for ingestion and serving services to Google App Engine.
Kubeflow provides choice in the form of Kubeflow Pipelines, Argo, and Katib in terms of how to experiment and train models.

There is much, much more to DevOps and MLOps. More about that another time...

# Troubleshooting

## Failed start script

## Failed App Engine service

If a service does not come up, go to the App Engine dashboard and look for the relevant service. Look at the logs for clues as to why it might be failing.
