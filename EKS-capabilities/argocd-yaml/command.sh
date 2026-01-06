#!/bin/bash

REGION="ap-southeast-1"
CLUSTER_NAME="test-cluster"
ACCOUNT_ID="830427153490"

# Step 1: Create IAM Role for ArgoCD Capability
echo "=== Step 1: Setting up IAM Role ==="

cat > argocd-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "capabilities.eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Check if role exists
aws iam get-role --role-name ArgoCDCapabilityRole &>/dev/null
if [ $? -ne 0 ]; then
    echo "Creating ArgoCDCapabilityRole..."
    aws iam create-role \
        --role-name ArgoCDCapabilityRole \
        --assume-role-policy-document file://argocd-trust-policy.json
else
    echo "Role ArgoCDCapabilityRole already exists"
fi

# Step 2: Attach necessary policies
echo -e "\n=== Step 2: Attaching IAM Policies ==="

cat > argocd-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:DescribeCluster",
                "eks:ListClusters",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret"
            ],
            "Resource": "*"
        }
    ]
}
EOF

aws iam put-role-policy \
    --role-name ArgoCDCapabilityRole \
    --policy-name ArgoCDEKSAccess \
    --policy-document file://argocd-policy.json

# Step 3: Create ArgoCD Capability with Configuration
echo -e "\n=== Step 3: Creating ArgoCD Capability with Configuration ==="

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/ArgoCDCapabilityRole"

# Create ArgoCD capability with minimal configuration
aws eks create-capability \
    --region $REGION \
    --cluster-name $CLUSTER_NAME \
    --capability-name argocd \
    --type ARGOCD \
    --role-arn $ROLE_ARN \
    --delete-propagation-policy RETAIN \
    --configuration '{
        "argoCd": {
            "namespace": "argocd"
        }
    }'

# Step 4: Verify
echo -e "\n=== Step 4: Verifying Setup ==="

echo "Waiting for capability to initialize..."
sleep 30

aws eks describe-capability \
    --region $REGION \
    --cluster-name $CLUSTER_NAME \
    --capability-name argocd \
    --query 'capability.{Status:status,Type:type,RoleArn:roleArn}' \
    --output table

# Check ArgoCD namespace and pods
echo -e "\nChecking ArgoCD pods..."
kubectl get pods -n argocd

echo -e "\nCleanup temporary files..."
rm -f argocd-trust-policy.json argocd-policy.json

echo -e "\n✅ Done! ArgoCD capability is being set up."