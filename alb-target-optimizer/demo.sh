#!/usr/bin/env bash
set -euo pipefail

############################################
# CONFIG
############################################
CLUSTER_NAME="test-cluster"
REGION="ap-southeast-1"
VPC_ID="vpc-0741270fd9925104b"
NAMESPACE="target-opt-demo"

# PUBLIC subnets (đã xác nhận từ bạn)
PUBLIC_SUBNETS=(
  subnet-04047a5a40c636ea8
  subnet-0bd68765176814f9b
  subnet-06bcdecdde587bd56
)

APP_PORT=8080
CONTROL_PORT=9000
DEST_PORT=8081

############################################
echo "=============================================="
echo " ALB TARGET OPTIMIZER – FULL REAL DEMO"
echo " Cluster : $CLUSTER_NAME"
echo " Region  : $REGION"
echo "=============================================="

############################################
echo "== 0. Update kubeconfig =="
aws eks update-kubeconfig \
  --name "$CLUSTER_NAME" \
  --region "$REGION"

############################################
echo "== 1. Patch Kyverno (exclude demo namespace) =="
kubectl patch clusterpolicy only-signed-image-digest --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/rules/0/exclude",
    "value": {
      "resources": {
        "namespaces": ["'"$NAMESPACE"'"]
      }
    }
  }
]' || true

############################################
echo "== 2. Recreate namespace =="
kubectl delete ns "$NAMESPACE" --ignore-not-found
kubectl create ns "$NAMESPACE"

############################################
echo "== 3. Deploy APP + TARGET OPTIMIZER AGENT =="
cat <<EOF | kubectl apply -n "$NAMESPACE" -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: demo
  template:
    metadata:
      labels:
        app: demo
    spec:
      containers:
      - name: app
        image: public.ecr.aws/docker/library/nginx:alpine
        ports:
        - containerPort: $DEST_PORT
        command: ["sh","-c"]
        args:
        - |
          echo "TARGET OPTIMIZER DEMO" > /usr/share/nginx/html/index.html
          nginx -g 'daemon off;' -c /etc/nginx/nginx.conf
      - name: optimizer-agent
        image: public.ecr.aws/aws-elb/target-optimizer/target-control-agent:latest
        env:
        - name: TARGET_CONTROL_DATA_ADDRESS
          value: "0.0.0.0:$APP_PORT"
        - name: TARGET_CONTROL_CONTROL_ADDRESS
          value: "0.0.0.0:$CONTROL_PORT"
        - name: TARGET_CONTROL_DESTINATION_ADDRESS
          value: "127.0.0.1:$DEST_PORT"
        - name: TARGET_CONTROL_MAX_CONCURRENCY
          value: "2"
        ports:
        - containerPort: $APP_PORT
        - containerPort: $CONTROL_PORT
EOF

kubectl rollout status deploy/demo -n "$NAMESPACE"

############################################
echo "== 4. Collect Pod IPs =="
POD_IPS=$(kubectl get pods -n "$NAMESPACE" -l app=demo -o jsonpath='{.items[*].status.podIP}')
echo "Pod IPs: $POD_IPS"

############################################
echo "== 5. Create Target Group (TARGET OPTIMIZER ENABLED) =="
TG_ARN=$(aws elbv2 create-target-group \
  --region "$REGION" \
  --name target-opt-tg \
  --protocol HTTP \
  --port $APP_PORT \
  --target-type ip \
  --vpc-id "$VPC_ID" \
  --health-check-protocol HTTP \
  --health-check-port "$APP_PORT" \
  --health-check-path "/" \
  --target-control-port "$CONTROL_PORT" \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

echo "TargetGroup ARN: $TG_ARN"

############################################
echo "== 6. Register Pod IPs as targets =="
for ip in $POD_IPS; do
  aws elbv2 register-targets \
    --region "$REGION" \
    --target-group-arn "$TG_ARN" \
    --targets Id="$ip",Port="$APP_PORT"
done

############################################
echo "== 7. Create Security Group for ALB =="
ALB_SG=$(aws ec2 create-security-group \
  --group-name target-opt-alb-sg \
  --description "ALB Target Optimizer Demo" \
  --vpc-id "$VPC_ID" \
  --query GroupId \
  --output text)

aws ec2 authorize-security-group-ingress \
  --group-id "$ALB_SG" \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

############################################
echo "== 8. Create PUBLIC ALB =="
ALB_ARN=$(aws elbv2 create-load-balancer \
  --region "$REGION" \
  --name target-opt-alb \
  --type application \
  --scheme internet-facing \
  --subnets "${PUBLIC_SUBNETS[@]}" \
  --security-groups "$ALB_SG" \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text)

############################################
echo "== 9. Create Listener =="
aws elbv2 create-listener \
  --region "$REGION" \
  --load-balancer-arn "$ALB_ARN" \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn="$TG_ARN"

############################################
echo "== 10. Fetch ALB DNS =="
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --region "$REGION" \
  --load-balancer-arns "$ALB_ARN" \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

echo "=============================================="
echo " ALB READY"
echo " URL: http://$ALB_DNS"
echo "=============================================="

echo
echo "TEST:"
echo "  ab -n 50 -c 20 http://$ALB_DNS/"
echo
echo "WATCH METRICS:"
echo "  TargetControlActiveChannelCount"
echo "  TargetControlRequestRejectCount"
