#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="test-cluster"
NAMESPACE="load-test"
JOB_NAME="apiserver-stress-hard"
METRIC_FILE="/tmp/apiserver-metrics-$(date +%s).txt"

echo "================================================="
echo " EKS Provisioned Control Plane Demo (HARD LOAD)"
echo " Cluster: ${CLUSTER_NAME}"
echo "================================================="

echo
echo "1. Checking current control plane tier..."
aws eks describe-cluster \
  --name "${CLUSTER_NAME}" \
  --query "cluster.controlPlaneScalingConfig" \
  --output json

echo
echo "2. Freezing Karpenter (prevent node eviction)..."
if kubectl get deployment karpenter -n karpenter >/dev/null 2>&1; then
  kubectl scale deployment karpenter -n karpenter --replicas=0
  echo "✓ Karpenter scaled to 0"
else
  echo "✓ Karpenter not found, skipping"
fi

echo
echo "3. Ensuring metrics-server is installed..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml >/dev/null 2>&1 || true

echo "Waiting for metrics-server..."
sleep 20
kubectl top nodes || echo "⚠ metrics-server not ready yet (OK for demo)"

echo
echo "4. Preparing load test namespace..."
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo
echo "5. Cleaning up previous stress jobs..."
kubectl delete job -n "${NAMESPACE}" --all --ignore-not-found
kubectl delete configmap -n "${NAMESPACE}" --all --ignore-not-found

echo
echo "6. Deploying HARD API server stress job..."
cat << 'EOF' | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: apiserver-stress-hard
  namespace: load-test
spec:
  parallelism: 150
  completions: 1500
  backoffLimit: 0
  template:
    spec:
      containers:
      - name: kubectl
        image: bitnami/kubectl:latest
        command:
        - sh
        - -c
        - |
          for i in $(seq 1 200); do
            kubectl create configmap cm-$HOSTNAME-$i \
              --from-literal=a=b \
              --dry-run=client -o yaml | kubectl apply -f -
            kubectl delete configmap cm-$HOSTNAME-$i
          done
      restartPolicy: Never
EOF

echo
echo "7. Waiting for load to ramp up..."
sleep 40

echo
echo "8. Capturing API server metrics..."
kubectl get --raw='/metrics' > "${METRIC_FILE}"
echo "✓ Metrics saved to ${METRIC_FILE}"

echo
echo "9. Key control plane indicators:"
echo "-------------------------------------------------"
echo "Inflight requests:"
grep apiserver_current_inflight_requests "${METRIC_FILE}" || true
echo
echo "Request throttling:"
grep apiserver_request_total "${METRIC_FILE}" | grep throttled || echo "✓ No throttling detected"
echo
echo "Latency buckets (look for high buckets):"
grep apiserver_request_duration_seconds_bucket "${METRIC_FILE}" | tail -10 || true
echo "-------------------------------------------------"

echo
echo "10. Job status:"
kubectl get jobs -n "${NAMESPACE}"

echo
echo "11. Node status (node pressure is OK for demo):"
kubectl get nodes

echo
echo "================================================="
echo " Demo step complete."
echo " If STANDARD shows high inflight / latency,"
echo " upgrade to tier-XL and re-run THIS SAME SCRIPT."
echo "================================================="
