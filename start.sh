# Set variables

INCEPTION_PROJECT="ca-inception"

STATE_BUCKET="climate-analytics-inception-terraform-state"
REGION="europe-west2"
PROJECT=$(awk -F"\"" '/^project / { print $2 }' infra/terraform.tfvars)
BILLING_ACCOUNT=$(awk -F"\"" '/^billing_account / { print $2 }' infra/terraform.tfvars)

if [ ${PROJECT} == "" ]; then
  echo "PROJECT value is empty, please set it manually"
  exit 1
else
  echo "The project will be ${PROJECT}"
fi

if [ ${BILLING_ACCOUNT} == "" ]; then
  echo "BILLING_ACCOUNT value is empty, please set it manually"
  exit 1
fi

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
  gcloud alpha billing accounts projects link ${INCEPTION_PROJECT} --billing-account ${BILLING_ACCOUNT}
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
if [ $? -eq 0 ]; then
  echo "It isn't."
  echo "Deploying app ..."
  yes y | gcloud app deploy # auto approve

  echo "Initiating get request ..."
  curl https://${PROJECT}.appspot.com/
  echo
fi

cd -

# Push web service code

echo "Now to deploy the web service"

work_dir=$(pwd)
temp_dir=/tmp/climate-analytics-webservice
source_repo=ncei-wind
webservice=ncei_wind

echo "Changing to temporary directory ..."
mkdir $temp_dir && cd $temp_dir
echo "Cloning web service repo ..."
gcloud source repos clone ${source_repo}

echo "Copying files from inception repo ..."
cd ${source_repo}
cp -a ${work_dir}/webservice/${webservice}/* .

echo "Checking if app is already running ..."
curl https://${source_repo}-dot-${PROJECT}.appspot.com/ | grep -q "ok"
if [ $? -eq 0 ]; then
  echo "It isn't."
  echo "Pushing code to deploy app ..."
  git add .
  git commit -m "Initial commit"
  git push origin master
fi

echo "Moving back to original directory ..."
cd ${work_dir}
echo "Deleting temporary directory ..."
rm -rf ${temp_dir}

echo
echo "*** Done! ***"
