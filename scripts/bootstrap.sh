#!/usr/bin/env bash
set -euo pipefail

AWS_PROFILE="${AWS_PROFILE:-modelops}"
AWS_REGION="${AWS_REGION:-us-east-1}"
ALLOWED_CIDR="${ALLOWED_CIDR:-164.52.212.58/32}"

APP_VERSION="1.5.6"
PROXY_VERSION="2.11.6"

PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFRA_DIR="${PLATFORM_DIR}/infra"
CANDIDATE_DIR="${RELEASELOCK_CANDIDATE_DIR:-$HOME/projects/releaselock-candidate}"

export AWS_PROFILE
export AWS_REGION

echo
echo "ReleaseLock lab bootstrap"
echo "AWS profile : ${AWS_PROFILE}"
echo "AWS region  : ${AWS_REGION}"
echo "Allowed CIDR: ${ALLOWED_CIDR}"
echo

command -v aws >/dev/null
command -v terraform >/dev/null
command -v docker >/dev/null

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
STATE_BUCKET="releaselock-tfstate-${ACCOUNT_ID}"

echo "AWS account : ${ACCOUNT_ID}"
echo "State bucket: ${STATE_BUCKET}"

if ! aws s3api head-bucket --bucket "${STATE_BUCKET}" 2>/dev/null; then
  echo
  echo "Terraform state bucket does not exist."
  echo "Expected: ${STATE_BUCKET}"
  exit 1
fi

echo
echo "== Terraform =="
cd "${INFRA_DIR}"

terraform init -reconfigure \
  -backend-config="bucket=${STATE_BUCKET}" \
  -backend-config="key=lab/terraform.tfstate" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="encrypt=true" \
  -backend-config="use_lockfile=true"

terraform fmt -check
terraform validate

terraform plan \
  -var="allowed_cidr=${ALLOWED_CIDR}" \
  -out=lab.tfplan

echo
echo "Applying infrastructure..."
terraform apply lab.tfplan
rm -f lab.tfplan

echo
echo "== ECR login =="

aws ecr get-login-password --region "${AWS_REGION}" |
  docker login \
    --username AWS \
    --password-stdin "${REGISTRY}"

echo
echo "== InvenTree image =="

docker pull "inventree/inventree:${APP_VERSION}"

docker tag \
  "inventree/inventree:${APP_VERSION}" \
  "${REGISTRY}/releaselock-app:${APP_VERSION}"

docker push \
  "${REGISTRY}/releaselock-app:${APP_VERSION}"

echo
echo "== Proxy image =="

if [[ ! -f "${CANDIDATE_DIR}/proxy/Dockerfile" ]]; then
  echo "Missing ${CANDIDATE_DIR}/proxy/Dockerfile"
  exit 1
fi

if [[ ! -f "${CANDIDATE_DIR}/proxy/Caddyfile" ]]; then
  echo "Missing ${CANDIDATE_DIR}/proxy/Caddyfile"
  exit 1
fi

docker build \
  -t "releaselock-proxy:${PROXY_VERSION}" \
  "${CANDIDATE_DIR}/proxy"

docker run --rm \
  "releaselock-proxy:${PROXY_VERSION}" \
  caddy validate --config /etc/caddy/Caddyfile

docker tag \
  "releaselock-proxy:${PROXY_VERSION}" \
  "${REGISTRY}/releaselock-proxy:${PROXY_VERSION}"

docker push \
  "${REGISTRY}/releaselock-proxy:${PROXY_VERSION}"

echo
echo "== Image digests =="

APP_DIGEST=$(aws ecr describe-images \
  --repository-name releaselock-app \
  --image-ids "imageTag=${APP_VERSION}" \
  --query 'imageDetails[0].imageDigest' \
  --output text)

PROXY_DIGEST=$(aws ecr describe-images \
  --repository-name releaselock-proxy \
  --image-ids "imageTag=${PROXY_VERSION}" \
  --query 'imageDetails[0].imageDigest' \
  --output text)

echo
echo "APP_DIGEST=${APP_DIGEST}"
echo "PROXY_DIGEST=${PROXY_DIGEST}"

echo
echo "== Terraform outputs =="
cd "${INFRA_DIR}"
terraform output

echo
echo "ReleaseLock base lab is ready."
echo
echo "Next unfinished step:"
echo "  database users + secret values, then ECS."
