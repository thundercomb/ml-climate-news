# Set variables

STATE_BUCKET="climate-analytics-inception"

# Prepare the environment

echo "Making storage bucket ..."
gsutil ls | grep -q gs://${STATE_BUCKET}/ || gsutil mb  -l europe-west2 gs://${STATE_BUCKET}/

# Create infrastructure

cd infra

terraform init -backend-config="bucket=${STATE_BUCKET}"
terraform plan
terraform apply -auto-approve
