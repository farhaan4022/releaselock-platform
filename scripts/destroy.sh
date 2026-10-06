#!/usr/bin/env bash
set -euo pipefail

AWS_PROFILE="${AWS_PROFILE:-modelops}"
AWS_REGION="${AWS_REGION:-us-east-1}"
ALLOWED_CIDR="${ALLOWED_CIDR:-164.52.212.58/32}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFRA_DIR="${ROOT_DIR}/infra"

export AWS_PROFILE
export AWS_REGION

echo
echo "ReleaseLock lab destroy"
echo "AWS profile : ${AWS_PROFILE}"
echo "AWS region  : ${AWS_REGION}"
echo

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "AWS account : ${ACCOUNT_ID}"
echo
echo "This will delete the Terraform-managed ReleaseLock lab."
echo "The Terraform state S3 bucket will be kept for future rebuilds."
echo
echo "RDS and EFS lab data will be deleted."
echo

read -r -p "Type destroy to continue: " ANSWER

if [[ "${ANSWER}" != "destroy" ]]; then
  echo "Cancelled."
  exit 0
fi

cd "${INFRA_DIR}"

terraform init -reconfigure \
  -backend-config="bucket=releaselock-tfstate-${ACCOUNT_ID}" \
  -backend-config="key=lab/terraform.tfstate" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="encrypt=true" \
  -backend-config="use_lockfile=true"

terraform plan \
  -destroy \
  -var="allowed_cidr=${ALLOWED_CIDR}" \
  -out=destroy.tfplan

echo
echo "Destroying lab..."
echo

terraform apply destroy.tfplan

rm -f destroy.tfplan

echo
echo "Terraform state:"
terraform state list || true

echo
echo "ReleaseLock AWS lab destroyed."
echo "State bucket retained: releaselock-tfstate-${ACCOUNT_ID}"
