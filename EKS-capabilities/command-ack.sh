#!/bin/bash

# Set variables
REGION="ap-southeast-1"
CLUSTER_NAME="test-cluster"
CAPABILITY_NAME="ack-capability"

# Get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create ACK capability for EKS cluster
aws eks create-capability \
  --region $REGION \
  --cluster-name $CLUSTER_NAME \
  --capability-name ack \
  --type ACK \
  --role-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/ACKCapabilityRole \
  --delete-propagation-policy RETAIN