#!/usr/bin/env bash
set -euo pipefail

# =========================
# CONFIG (FIXED FOR YOU)
# =========================
CLUSTER_NAME="test-cluster"
REGION="ap-southeast-1"
ACCOUNT_ID="830427153490"
OIDC_ID="5498F917375A9E98B1FA8AD475DF8200"

ROLE_NAME="EKS-CloudWatch-Observability-Role"
ADDON_NAME="amazon-cloudwatch-observability"

echo "================================================="
echo " EKS ENO + CloudWatch Observability Setup"
echo " Cluster : ${CLUSTER_NAME}"
echo " Region  : ${REGION}"
echo " Account : ${ACCOUNT_ID}"
echo "================================================="

# -------------------------------------------------
# 0. kubeconfig
# -------------------------------------------------
echo
echo "0. Updating kubeconfig..."
aws eks update-kubeconfig \
  --name "${CLUSTER_NAME}" \
  --region "${REGION}" >/dev/null
echo "✓ kubeconfig updated"

# -------------------------------------------------
# 1. Create IAM trust policy
# -------------------------------------------------
echo
echo "1. Creating IAM trust policy..."

cat > cw-observability-trust.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/oidc.eks.${REGION}.amazonaws.com/id/${OIDC_ID}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.${REGION}.amazonaws.com/id/${OIDC_ID}:sub": "system:serviceaccount:amazon-cloudwatch:cloudwatch-agent"
        }
      }
    }
  ]
}
EOF

# -------------------------------------------------
# 2. Create IAM role (if not exists)
# -------------------------------------------------
echo
echo "2. Creating IAM role (if needed)..."

if aws iam get-role --role-name "${ROLE_NAME}" >/dev/null 2>&1; then
  echo "✓ IAM role already exists"
else
  aws iam create-role \
    --role-name "${ROLE_NAME}" \
    --assume-role-policy-document file://cw-observability-trust.json
  echo "✓ IAM role created"
fi

# -------------------------------------------------
# 3. Attach CloudWatch policy
# -------------------------------------------------
echo
echo "3. Attaching CloudWatchAgentServerPolicy..."

aws iam attach-role-policy \
  --role-name "${ROLE_NAME}" \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy

echo "✓ Policy attached"

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

# -------------------------------------------------
# 4. Delete failed addon (if exists)
# -------------------------------------------------
echo
echo "4. Cleaning up failed addon (if exists)..."

if aws eks describe-addon \
  --cluster-name "${CLUSTER_NAME}" \
  --addon-name "${ADDON_NAME}" >/dev/null 2>&1; then

  aws eks delete-addon \
    --cluster-name "${CLUSTER_NAME}" \
    --addon-name "${ADDON_NAME}"

  echo "Waiting for addon deletion..."
  aws eks wait addon-deleted \
    --cluster-name "${CLUSTER_NAME}" \
    --addon-name "${ADDON_NAME}"
fi

echo "✓ Addon state clean"

# -------------------------------------------------
# 5. Create CloudWatch Observability addon
# -------------------------------------------------
echo
echo "5. Installing CloudWatch Observability addon..."

aws eks create-addon \
  --cluster-name "${CLUSTER_NAME}" \
  --addon-name "${ADDON_NAME}" \
  --service-account-role-arn "${ROLE_ARN}"

echo "Waiting for addon to become ACTIVE..."
aws eks wait addon-active \
  --cluster-name "${CLUSTER_NAME}" \
  --addon-name "${ADDON_NAME}"

echo "✓ Addon installed successfully"

# -------------------------------------------------
# 6. Verify pods
# -------------------------------------------------
echo
echo "6. Verifying CloudWatch pods..."

kubectl get pods -n amazon-cloudwatch

# -------------------------------------------------
# DONE
# -------------------------------------------------
echo
echo "================================================="
echo " SETUP COMPLETE"
echo "================================================="
echo
echo "Next steps for DEMO:"
echo "1. Wait 2–5 minutes"
echo "2. Open CloudWatch Console:"
echo "   CloudWatch → Container Insights → EKS → Network"
echo "3. Re-run ENO NetworkPolicy demo"
echo
echo "You should now see:"
echo "- Pod-to-Pod traffic"
echo "- Network drops after NetworkPolicy"
echo "- NO 'Not onboarded' banner"
echo
