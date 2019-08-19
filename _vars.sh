INCEPTION_PROJECT="ca-inception"

STATE_BUCKET="${INCEPTION_PROJECT}-terraform-state"
REGION="$(awk -F"\"" '/^region / { print $2 }' infra/terraform.tfvars)"
PROJECT="$(awk -F"\"" '/^project / { print $2 }' infra/terraform.tfvars)"
BILLING_ACCOUNT="$(awk -F"\"" '/^billing_account / { print $2 }' infra/terraform.tfvars)"

for var in INCEPTION_PROJECT STATE_BUCKET REGION PROJECT BILLING_ACCOUNT; do
  VAR="$(eval echo $`echo $var`)" # value of env var corresponding to string
  if [ "${VAR}" == "" ]; then
    echo "${var} value is empty, please set it manually"
    exit 1
  else
    echo "${var}=\"${VAR}\""
    export ${var}
  fi
done
