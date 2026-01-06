#!/bin/bash

REGION="ap-southeast-1"
CLUSTER_NAME="test-cluster"

echo "Reverting to Standard control plane mode..."
aws eks update-cluster-config \
    --region $REGION \
    --name $CLUSTER_NAME \
    --control-plane-scaling-config tier=standard

echo "Cluster will transition back to auto-scaling mode"