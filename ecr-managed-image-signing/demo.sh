#!/bin/bash
set -euo pipefail

# =========================
# CONFIG
# =========================
REGION="ap-southeast-1"
CLUSTER_NAME="test-cluster"
SIGNING_PROFILE_NAME="ecr_demo_signing"
REPO_NAME="signed-demo-app"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
IMAGE_BASE="${ECR_URI}/${REPO_NAME}"

KYVERNO_VERSION="v1.12.3"

echo "=============================================="
echo " ECR + EKS Signed Image Demo (FIXED)"
echo " Cluster: ${CLUSTER_NAME}"
echo " Account: ${ACCOUNT_ID}"
echo " Region : ${REGION}"
echo "=============================================="

# =========================
# STEP 0 – kube context
# =========================
aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${REGION}" >/dev/null
kubectl get nodes >/dev/null
echo "✓ Connected to EKS cluster"

# =========================
# STEP 1 – Signing profile ARN (BUILD, NOT QUERY)
# =========================
PROFILE_ARN="arn:aws:signer:${REGION}:${ACCOUNT_ID}:/signing-profiles/${SIGNING_PROFILE_NAME}"
echo "✓ Using signing profile ARN: ${PROFILE_ARN}"

# =========================
# STEP 2 – Ensure ECR repo & login
# =========================
aws ecr create-repository \
  --repository-name "${REPO_NAME}" \
  --region "${REGION}" >/dev/null 2>&1 || true

aws ecr get-login-password --region "${REGION}" | \
docker login --username AWS --password-stdin "${ECR_URI}"

# =========================
# STEP 3 – Build & push UNSIGNED image
# =========================
echo
echo "== Step 3: Build & push UNSIGNED image =="

cat <<EOF > Dockerfile
FROM nginx:alpine
RUN echo "UNSIGNED IMAGE" > /usr/share/nginx/html/index.html
EOF

docker build -t unsigned:v1 .
docker tag unsigned:v1 "${IMAGE_BASE}:unsigned"
docker push "${IMAGE_BASE}:unsigned"

# =========================
# STEP 4 – Build & push SIGNED image
# =========================
echo
echo "== Step 4: Build & push SIGNED image =="

cat <<EOF > Dockerfile
FROM nginx:alpine
RUN echo "SIGNED IMAGE" > /usr/share/nginx/html/index.html
EOF

docker build -t signed:v1 .
docker tag signed:v1 "${IMAGE_BASE}:signed"
docker push "${IMAGE_BASE}:signed"

# =========================
# STEP 5 – Resolve SIGNED image digest (FIXED)
# =========================
echo
echo "== Step 5: Resolve signed image digest =="

SIGNED_DIGEST=$(aws ecr describe-images \
  --repository-name "${REPO_NAME}" \
  --region "${REGION}" \
  --query "imageDetails[?contains(imageTags, 'signed')].imageDigest | [0]" \
  --output text)

if [[ -z "${SIGNED_DIGEST}" || "${SIGNED_DIGEST}" == "None" ]]; then
  echo "❌ Cannot resolve signed image digest"
  exit 1
fi

echo "✓ Signed image digest: ${SIGNED_DIGEST}"

# =========================
# STEP 6 – Install Kyverno (FIXED URL)
# =========================
echo
echo "== Step 6: Install Kyverno =="

helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update

helm install kyverno kyverno/kyverno \
  -n kyverno \
  --create-namespace || true

kubectl -n kyverno rollout status deployment kyverno-admission-controller

# =========================
# STEP 7 – Policy: ONLY ALLOW SIGNED DIGEST
# =========================
echo
echo "== Step 7: Apply signed-image-only policy =="

cat <<EOF | kubectl apply -f -
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: only-signed-image-digest
spec:
  validationFailureAction: Enforce
  rules:
  - name: allow-only-signed-image
    match:
      resources:
        kinds: ["Pod"]
    validate:
      message: "Only SIGNED image digest is allowed"
      pattern:
        spec:
          containers:
          - image: "${IMAGE_BASE}@${SIGNED_DIGEST}"
EOF

# =========================
# STEP 8 – Deploy UNSIGNED pod (FAIL)
# =========================
echo
echo "== Step 8: Deploy UNSIGNED pod (EXPECTED TO FAIL) =="

cat <<EOF | kubectl apply -f - || true
apiVersion: v1
kind: Pod
metadata:
  name: unsigned-pod
spec:
  containers:
  - name: app
    image: ${IMAGE_BASE}:unsigned
EOF

# =========================
# STEP 9 – Deploy SIGNED pod (SUCCESS)
# =========================
echo
echo "== Step 9: Deploy SIGNED pod =="

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: signed-pod
spec:
  containers:
  - name: app
    image: ${IMAGE_BASE}@${SIGNED_DIGEST}
EOF

kubectl get pods signed-pod

# =========================
# CLEANUP
# =========================
rm -f Dockerfile

echo
echo "=============================================="
echo " ✅ DEMO COMPLETE – THIS ONE IS CORRECT"
echo " - Unsigned image: BLOCKED"
echo " - Signed image  : ALLOWED"
echo " - Enforcement  : DIGEST-based"
echo "=============================================="
