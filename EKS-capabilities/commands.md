```
aws iam create-role \
  --role-name ACKCapabilityRole \
  --assume-role-policy-document file://ack-trust-policy.json

aws iam attach-role-policy \
  --role-name ACKCapabilityRole \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

```
aws eks create-capability \
  --region $REGION \
  --cluster-name $CLUSTER_NAME \
  --capability-name ack \
  --type ACK \
  --role-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/ACKCapabilityRole \
  --delete-propagation-policy RETAIN
```
result: 
```
{
    "capability": {
        "capabilityName": "ack",
        "arn": "arn:aws:eks:ap-southeast-1:830427153490:capability/test-cluster/ack/ack/c2cdca34-07bc-88f6-e2bd-bb6713175c37",
        "clusterName": "test-cluster",
        "type": "ACK",
        "roleArn": "arn:aws:iam::830427153490:role/ACKCapabilityRole",
        "status": "CREATING",
        "configuration": {},
        "tags": {},
        "health": {
            "issues": []
        },
        "createdAt": "2026-01-06T17:43:27.373000+00:00",
        "modifiedAt": "2026-01-06T17:43:27.373000+00:00",
        "deletePropagationPolicy": "RETAIN"
    }
}
```

```
aws eks update kube-config --name test-cluster

kubectl api-resources | grep services.k8s.aws
```
# Creating AWS resources with ACK

```
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
export BUCKET_NAME=my-production-bucket-$AWS_ACCOUNT_ID

read -r -d '' BUCKET_MANIFEST <<EOF
apiVersion: s3.services.k8s.aws/v1alpha1
kind: Bucket
metadata:
  name: $BUCKET_NAME
spec:
  name: $BUCKET_NAME
  versioning:
    status: Enabled
  encryption:
    rules:
      - applyServerSideEncryptionByDefault:
          sseAlgorithm: AES256
  lifecycle:
    rules:
      - id: delete-old-versions
        filter:
          prefix: ""
        status: Enabled
        noncurrentVersionExpiration:
          noncurrentDays: 90
  publicAccessBlock:
    blockPublicACLs: true
    blockPublicPolicy: true
    ignorePublicACLs: true
    restrictPublicBuckets: true
EOF

echo "${BUCKET_MANIFEST}" > bucket.yaml
kubectl apply -f bucket.yaml
```
# Creation is complete when you receive a response like the one below:

bucket.s3.services.k8s.aws/my-production-bucket-xxxxxxxxxxxx created

# Confirm that the status ACK.ResourceSyncedis correct

```
kubectl describe bucket.s3.services.k8s.aws
```

You can also verify that the corresponding S3 bucket is created:
```
aws s3 ls | grep "my-production-bucket"
```

Xoá app:
```
kubectl patch application guestbook -n argocd \
  --type json \
  --patch='[{"op": "remove", "path": "/metadata/finalizers"}]'
```

Argo CD had limited functionality compared to the upstream version, such as the Notifications controller.
In the case of ACK, there are no limitations compared to upstream,
but only services that the controller has made GA are available.


The reconciliation loop triggers when:
- You create, update, or delete a resource in Kubernetes
- The periodic sync interval expires (default: 10 hours, configurable per controller)
- Controller restarts

# Try out the AWS-managed Argo CD

Restrictions on using Argo CD in EKS Capabilities
Some Argo CD features are not available in EKS Capabilities.

Unsupported features: The following features are not available in the managed capability:
・Config Management Plugins (CMPs) for custom manifest generation
・Custom Lua scripts for resource health assessment (built-in health checks for standard resources are supported)
・The Notifications controller
・Argo CD Image Updater
・Custom SSO providers (only AWS Identity Center is supported)
・UI extensions and custom banners
・Direct access to argocd-cm, argocd-params, and other configuration ConfigMaps

If you need these features, you will need to self-host them on EKS.
If you are using the Notification feature in particular, you will need to be careful when migrating.


Simply enabling the feature delivered the Argo CD UI, complete with authentication via the IAM Identity Center, which was a very pleasant experience. With
access entries, Pod Identity, community add-ons, Auto Mode, and EKS Capabilities, the EKS development experience has improved dramatically over the past few years, which makes me very happy.
However, a high level of abstraction can also make it difficult to isolate issues, so I'm looking forward to future support for things like log output.