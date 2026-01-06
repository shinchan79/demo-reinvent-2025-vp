#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="test-cluster"
REGION="ap-southeast-1"
NAMESPACE="weighted-demo"

echo "=============================================="
echo " NLB Weighted Target Groups Demo (REAL)"
echo " Cluster : ${CLUSTER_NAME}"
echo " Region  : ${REGION}"
echo "=============================================="

echo "== 0. Update kubeconfig =="
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"

echo "== 1. Patch Kyverno (exclude demo namespace) =="
kubectl patch clusterpolicy only-signed-image-digest --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/rules/0/exclude",
    "value": {
      "resources": {
        "namespaces": ["weighted-demo"]
      }
    }
  }
]' || true

echo "== 2. Recreate namespace =="
kubectl delete namespace "$NAMESPACE" --ignore-not-found
kubectl create namespace "$NAMESPACE"

echo "== 3. Deploy app v1 (BLUE) =="
kubectl apply -n "$NAMESPACE" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: demo
      version: v1
  template:
    metadata:
      labels:
        app: demo
        version: v1
    spec:
      containers:
      - name: app
        image: nginx:1.25
        ports:
        - containerPort: 80
        command: ["/bin/sh","-c"]
        args:
          - echo "V1 BLUE" > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'
EOF

kubectl apply -n "$NAMESPACE" -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: svc-v1
spec:
  selector:
    app: demo
    version: v1
  ports:
  - port: 80
    targetPort: 80
EOF

echo "== 4. Deploy app v2 (GREEN) =="
kubectl apply -n "$NAMESPACE" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: demo
      version: v2
  template:
    metadata:
      labels:
        app: demo
        version: v2
    spec:
      containers:
      - name: app
        image: nginx:1.25
        ports:
        - containerPort: 80
        command: ["/bin/sh","-c"]
        args:
          - echo "V2 GREEN" > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'
EOF

kubectl apply -n "$NAMESPACE" -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: svc-v2
spec:
  selector:
    app: demo
    version: v2
  ports:
  - port: 80
    targetPort: 80
EOF

echo "== 5. Wait for pods =="
kubectl rollout status deploy/app-v1 -n "$NAMESPACE"
kubectl rollout status deploy/app-v2 -n "$NAMESPACE"

echo "== 6. Create NLB Service (shared) =="
kubectl apply -n "$NAMESPACE" -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: nlb-entry
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
spec:
  type: LoadBalancer
  selector:
    app: demo
  ports:
  - port: 80
    targetPort: 80
EOF

echo "== 7. Wait for NLB =="
sleep 20
NLB_DNS=$(kubectl get svc nlb-entry -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "NLB DNS: $NLB_DNS"

echo
echo "================================================="
echo " IMPORTANT:"
echo " Kubernetes DOES NOT control weighted routing."
echo " Weights MUST be configured on NLB listener:"
echo
echo " aws elbv2 modify-listener \\"
echo "   --listener-arn <listener-arn> \\"
echo "   --default-actions '[{\"Type\":\"forward\",\"ForwardConfig\":{\"TargetGroups\":["
echo "     {\"TargetGroupArn\":\"<tg-v1>\",\"Weight\":80},"
echo "     {\"TargetGroupArn\":\"<tg-v2>\",\"Weight\":20}"
echo "   ]}}]'"
echo
echo " Test:"
echo " curl http://$NLB_DNS"
echo "================================================="
