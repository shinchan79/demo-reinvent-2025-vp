#!/usr/bin/env bash
set -euo pipefail

REGION="ap-southeast-1"
REPO="signed-demo-app"
TAG="signed"

echo "=============================================="
echo " Amazon ECR Archive Storage Class Demo"
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
echo "2. Archive image (storage class -> ARCHIVE)..."
aws ecr update-image-storage-class \
  --region ${REGION} \
  --repository-name ${REPO} \
  --image-id imageDigest=${DIGEST} \
  --target-storage-class ARCHIVE

echo "✓ Image archived"

echo
echo "3. Verify image status..."
aws ecr describe-images \
  --region ${REGION} \
  --repository-name ${REPO} \
  --image-ids imageDigest=${DIGEST} \
  --query 'imageDetails[0].imageStatus' \
  --output text

echo
echo "4. Demo pull failure (EXPECTED)..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
IMAGE_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO}:${TAG}"

set +e
docker pull ${IMAGE_URI}
set -e

echo
echo "================================================="
echo " EXPECTED RESULT:"
echo " - docker pull FAILS (404)"
echo " - Image status = ARCHIVED"
echo
echo " To restore:"
echo " aws ecr update-image-storage-class \\"
echo "   --repository-name ${REPO} \\"
echo "   --image-id imageDigest=${DIGEST} \\"
echo "   --target-storage-class STANDARD"
echo "================================================="
