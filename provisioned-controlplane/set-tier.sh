#!/bin/bash

REGION="ap-southeast-1"
CLUSTER_NAME="test-cluster"

echo "Set tier..."
aws eks update-cluster-config \
    --region $REGION \
    --name $CLUSTER_NAME \
    --control-plane-scaling-config tier=tier-xl

echo "Cluster will transition back to auto-scaling mode"