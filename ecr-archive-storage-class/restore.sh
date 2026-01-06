#!/usr/bin/env bash
set -euo pipefail

REGION="ap-southeast-1"
REPO="signed-demo-app"
TAG="signed"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
IMAGE_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO}:${TAG}"

echo "=============================================="
echo " ECR Restore & Pull Demo"
echo " Repo   : ${REPO}"
echo " Tag    : ${TAG}"
echo " Region : ${REGION}"
echo "=============================================="

echo
echo "1. Resolve image digest..."
DIGEST=$(aws ecr describe-images \
  --region ${REGION} \
  --repository-name ${REPO} \
  --image-ids imageTag=${TAG} \
  --query 'imageDetails[0].imageDigest' \
  --output text)

if [[ -z "$DIGEST" || "$DIGEST" == "None" ]]; then
  echo "❌ Cannot resolve image digest"
  exit 1
fi

echo "✓ Image digest: ${DIGEST}"

echo
echo "2. Restore image (ARCHIVE → STANDARD)..."
aws ecr update-image-storage-class \
  --region ${REGION} \
  --repository-name ${REPO} \
  --image-id imageDigest=${DIGEST} \
  --target-storage-class STANDARD

echo "✓ Restore request submitted"

echo
echo "3. Waiting until image becomes ACTIVE..."
while true; do
  STATUS=$(aws ecr describe-images \
    --region ${REGION} \
    --repository-name ${REPO} \
    --image-ids imageDigest=${DIGEST} \
    --query 'imageDetails[0].imageStatus' \
    --output text)

  echo "   Current status: ${STATUS}"

  if [[ "$STATUS" == "ACTIVE" ]]; then
    break
  fi

  sleep 10
done

echo "✓ Image is ACTIVE"

echo
echo "4. Login to ECR..."
aws ecr get-login-password --region ${REGION} | \
  docker login --username AWS --password-stdin \
  ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

echo
echo "5. Pull restored image..."
docker pull ${IMAGE_URI}

echo
echo "================================================="
echo " SUCCESS"
echo " Image restored from ARCHIVE and pulled successfully"
echo "================================================="
