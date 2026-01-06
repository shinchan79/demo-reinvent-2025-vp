Cần tắt tạm demo signed nếu đã thực hiện:

```
kubectl patch clusterpolicy only-signed-image-digest --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/rules/0/exclude",
    "value": {
      "resources": {
        "namespaces": ["eno-demo", "amazon-cloudwatch"]
      }
    }
  }
]'
```
Nếu không tắt:
```
=================================================
 EKS Enhanced Network Observability Demo
 Mode   : EKS AUTO MODE
 Cluster: test-cluster
 Region : ap-southeast-1
=================================================

0. Updating kubeconfig...
✓ Connected to cluster

1. Checking Kubernetes version...
✓ Server version: v1.34.2-eks-b3126f4

2. Checking Enhanced Network Observability status...
{
    "serviceIpv4Cidr": "172.20.0.0/16",
    "ipFamily": "ipv4",
    "elasticLoadBalancing": {
        "enabled": true
    }
}
✓ ENO is managed automatically in EKS Auto Mode

3. Deploying demo workloads (client -> server)...
service/server created
Error from server: error when creating "STDIN": admission webhook "validate.kyverno.svc-fail" denied the request: 

resource Deployment/eno-demo/server was blocked due to the following policies 

only-signed-image-digest:
  autogen-allow-only-signed-image: 'validation error: Only SIGNED image digest is
    allowed. rule autogen-allow-only-signed-image failed at path /spec/template/spec/containers/0/image/'

Error from server: error when creating "STDIN": admission webhook "validate.kyverno.svc-fail" denied the request: 

resource Deployment/eno-demo/client was blocked due to the following policies 

only-signed-image-digest:
  autogen-allow-only-signed-image: 'validation error: Only SIGNED image digest is
    allowed. rule autogen-allow-only-signed-image failed at path /spec/template/spec/containers/0/image/'
```

Chạy demo:

```
AWSReservedSSO_AWSAdministratorAccess_4288b0790c6df772:~/environment/VPB-reinvent-recap-demos/demo-reinvent-2025-vp/Enhanced-Network-Observability (main) $ ./demo.sh 
=================================================
 EKS Enhanced Network Observability Demo
 Mode   : EKS AUTO MODE
 Cluster: test-cluster
 Region : ap-southeast-1
=================================================

0. Updating kubeconfig...
✓ Connected to cluster

1. Checking Kubernetes version...
✓ Server version: v1.34.2-eks-b3126f4

2. Checking Enhanced Network Observability status...
{
    "serviceIpv4Cidr": "172.20.0.0/16",
    "ipFamily": "ipv4",
    "elasticLoadBalancing": {
        "enabled": true
    }
}
✓ ENO is managed automatically in EKS Auto Mode

3. Deploying demo workloads (client -> server)...
deployment.apps/server created
service/server unchanged
deployment.apps/client created
Waiting for deployment "server" rollout to finish: 0 of 1 updated replicas are available...
deployment "server" successfully rolled out
deployment "client" successfully rolled out
✓ Traffic is ALLOWED

4. Applying NetworkPolicy (DENY client -> server)...
networkpolicy.networking.k8s.io/deny-client-to-server created
✓ NetworkPolicy applied
→ Traffic should now be BLOCKED

=================================================
 DEMO OBSERVATION (AUTO MODE)
=================================================

1. Client logs:
   kubectl -n eno-demo logs deploy/client

2. CloudWatch:
   CloudWatch → Container Insights → EKS → Network

   Observe:
   - Network drops
   - Policy denies
   - Pod-to-Pod visibility

=================================================
 DEMO COMPLETE
=================================================
```
Nếu bị không tìm được openid connect khi kiểm tra log:
```
kubectl -n amazon-cloudwatch logs daemonset/cloudwatch-agent | tail
```
Chạy: 

```
aws iam create-open-id-connect-provider \
  --url https://oidc.eks.ap-southeast-1.amazonaws.com/id/5498F917375A9E98B1FA8AD475DF8200 \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 9e99a48a9960b14926bb7f3b02e22da0ecd4f4a4
```

```
kubectl -n amazon-cloudwatch rollout restart daemonset cloudwatch-agent
kubectl -n amazon-cloudwatch rollout restart daemonset fluent-bit
```
```
kubectl get pods -n amazon-cloudwatch
```

```
aws cloudwatch list-metrics \
  --namespace AWS/EKS \
  --region ap-southeast-1 | head
```
