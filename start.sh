#!/bin/bash

# Set variables

source _vars.sh

# Prepare the environment
echo "Checking if inception project exists ..."
gcloud projects list | awk '{ print $1 }' | grep -q ^"${INCEPTION_PROJECT}"$
if [ $? -ne 0 ]; then
  echo "Inception project does not exist."
  echo "Making inception project ..."
  gcloud projects create ${INCEPTION_PROJECT}
fi

echo "Checking if inception terraform state bucket exists ..."
gsutil ls -p ${INCEPTION_PROJECT} | grep -q gs://${STATE_BUCKET}/
if [ $? -ne 0 ]; then
  echo "Inception terraform state bucket does not exist."
  echo "Linking billing account to project ..."
  gcloud beta billing projects link ${INCEPTION_PROJECT} --billing-account ${BILLING_ACCOUNT}
  echo "Change to inception project ..."
  gcloud config set project ${INCEPTION_PROJECT}
  echo "Making storage bucket ..."
  gsutil mb -l ${REGION} -p ${INCEPTION_PROJECT} gs://${STATE_BUCKET}/
fi

# Create infrastructure

cd infra

echo "Deploying infrastructure ..."

terraform init -backend-config="bucket=${STATE_BUCKET}"
terraform plan
terraform apply -auto-approve

cd -

# Deploy default service (App Engine compulsory)

echo "Default service is required by app engine - let's deploy it"
echo "Setting local gcloud to project ${PROJECT}"
gcloud config set project ${PROJECT}

cd webservice/default

echo "Checking if dummy default web service is already running ..."
curl https://${PROJECT}.appspot.com/ | grep -q "ok"
if [ $? -ne 0 ]; then
  echo "It isn't."
  echo "Deploying dummy default web service ..."
  yes y | gcloud app deploy # auto approve

  echo "Initiating get request ..."
  curl https://${PROJECT}.appspot.com/
  echo
fi

cd -

# Push web service code

echo "Deploying our real web services ..."

cd webservice

# Now deploy all webservices excluding default
for webservice in $(ls | sed 's/default//'); do

  work_dir=$(pwd)
  temp_dir=/tmp/${PROJECT}-${webservice}
  source_repo=${webservice/_/-}

  echo "Changing to temporary directory ..."
  mkdir $temp_dir && cd $temp_dir
  echo "Cloning web service repo ..."
  gcloud source repos clone ${source_repo}

  echo "Copying files from inception repo ..."
  cd ${source_repo}
  cp -a ${work_dir}/${webservice}/* .

  echo "Checking if web service is already running ..."
  gcloud app instances list --service=${source_repo} 2>&1 | grep -q ^"${source_repo} "
  if [ $? -ne 0 ]; then
    echo "It isn't."
    echo "Pushing code to deploy web service ..."
    git add .
    git commit -m "Initial commit"
    git push origin master
  fi

  echo "Moving back to original directory ..."
  cd ${work_dir}
  echo "Deleting temporary directory ..."
  rm -rf ${temp_dir}

done

echo
echo "*** Done! ***"
