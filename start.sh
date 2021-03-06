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
DONE=1
while [ $DONE -eq 1 ]; do
  terraform apply -auto-approve
  if [ $? -eq 0 ]; then
    DONE=0
  fi
done
GKE_CLUSTER_NAME=$(terraform output gke_cluster_name)
GKE_CLUSTER_IP=$(terraform output gke_cluster_ip)
cd -

# Deploy default service (App Engine compulsory)

echo "Default service is required by app engine - let's deploy it"
echo "Setting local gcloud to project ${PROJECT}"
gcloud config set project ${PROJECT}

cd webservices/default

echo "Checking if dummy default web service is already running ..."
curl https://${PROJECT}.appspot.com/ | grep -q "ok"
if [ $? -ne 0 ]; then
  echo "It isn't."
  echo "Deploying dummy default web service ..."
  yes y | gcloud app deploy # auto approve

  echo "Initiating get request ..."
  curl https://${PROJECT}.appspot.com/
  echo
else
  echo "Looks good."
fi

cd -

# Push web service code

echo "Deploying our ingestion microservices ..."

bash _webservices.sh ingest

echo "Deploying our serving web services ..."
echo "NOTE: Web services will fail to serve until machine learning models have been trained"

bash _webservices.sh serve

# Installing Kubeflow

echo "Checking if kubeflow cli is installed ..."
which kfctl && kfctl version || {
  echo "It isn't.";
  echo "Installing kfctl ...";
  opsys=darwin;
  curl -s https://api.github.com/repos/kubeflow/kubeflow/releases/latest |\
    grep browser_download |\
    grep $opsys |\
    cut -d '"' -f 4 |\
    xargs curl -O -L && \
    tar -zvxf kfctl_*_${opsys}.tar.gz;
  mv kfctl /usr/local/bin && rm kfctl_*_${opsys}.tar.gz;
}

cd mlops

echo "Getting GKE cluster credentials ..."
gcloud beta container clusters get-credentials ${GKE_CLUSTER_NAME} --region ${REGION} --project ${PROJECT}

echo "Checking if kubeflow config has been created already ..."
export KFAPP="kf-${PROJECT}"
if ! test -d $KFAPP; then
  echo "It hasn't."
  echo "Initialising, generating and applying configs ..."
  export CONFIG="https://raw.githubusercontent.com/kubeflow/kubeflow/v0.6-branch/bootstrap/config/kfctl_k8s_istio.0.6.2.yaml"
  kfctl init ${KFAPP} --config=${CONFIG} -V
  cd ${KFAPP}
  kfctl generate all -V
  kfctl apply all -V
  cd ..
fi

echo "Checking if kubectl cli is installed ..."
which kubectl && kubectl version || {
  echo "It isn't.";
  echo "Installing kubectl ...";
  curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl";
  mv kubectl /usr/local/bin;
}

STATUS="NO"
while [ "${STATUS}" != "" ]; do
  echo "Monitoring pods until they're all running, this could take a few minutes ..."
  STATUS=$(kubectl get pods --all-namespaces | awk '($4 != "Running" && $4 != "Completed" && $4 != "STATUS") { print $4 }')
  sleep 10
done

cd ..

# Render ml scripts from templates and push ml code to repos, triggering first builds

bash _ml.sh

# Port forward the ingress gateway to access kubeflow dashboard

echo "Port-forwarding the Istio ingress gateway ..."
echo "When it says 'Forwarding from ..' point your browser at localhost:8080"
export NAMESPACE=istio-system
echo "kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80"
kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80


echo
echo "*** Done! ***"
