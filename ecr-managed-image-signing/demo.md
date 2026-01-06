Key Benefits của Managed Signing:

Tự động sign images khi push - chỉ cần vài clicks hoặc một API call AWS
AWS Signer xử lý key material và certificate lifecycle management bao gồm generation, secure storage, và rotation AWS
Mọi signing operations đều được log qua CloudTrail để audit đầy đủ AWS
No client-side tools needed - không cần cài Notation CLI để sign
Integrated với EKS - có thể verify signatures trước khi deploy

```
./demo.sh 
==============================================
 ECR + EKS Signed Image Demo (FIXED)
 Cluster: test-cluster
 Account: 830427153490
 Region : ap-southeast-1
==============================================
✓ Connected to EKS cluster
✓ Using signing profile ARN: arn:aws:signer:ap-southeast-1:830427153490:/signing-profiles/ecr_demo_signing
WARNING! Your password will be stored unencrypted in /home/ec2-user/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded

== Step 3: Build & push UNSIGNED image ==
[+] Building 1.5s (6/6) FINISHED                                                                                                                                                                                                                                         docker:default
 => [internal] load build definition from Dockerfile                                                                                                                                                                                                                               0.0s
 => => transferring dockerfile: 175B                                                                                                                                                                                                                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:alpine                                                                                                                                                                                                                    1.4s
 => [internal] load .dockerignore                                                                                                                                                                                                                                                  0.0s
 => => transferring context: 2B                                                                                                                                                                                                                                                    0.0s
 => [1/2] FROM docker.io/library/nginx:alpine@sha256:8491795299c8e739b7fcc6285d531d9812ce2666e07bd3dd8db00020ad132295                                                                                                                                                              0.0s
 => CACHED [2/2] RUN echo "UNSIGNED IMAGE" > /usr/share/nginx/html/index.html                                                                                                                                                                                                      0.0s
 => exporting to image                                                                                                                                                                                                                                                             0.0s
 => => exporting layers                                                                                                                                                                                                                                                            0.0s
 => => writing image sha256:5b39e15d6cf158cd970b713efcc46294e403307604d02dfb9885663b44a86624                                                                                                                                                                                       0.0s
 => => naming to docker.io/library/unsigned:v1                                                                                                                                                                                                                                     0.0s
The push refers to repository [830427153490.dkr.ecr.ap-southeast-1.amazonaws.com/signed-demo-app]
733dc970495d: Layer already exists 
e6fe11fa5b7f: Layer already exists 
67ea0b046e7d: Layer already exists 
ed5fa8595c7a: Layer already exists 
8ae63eb1f31f: Layer already exists 
b3e3d1bbb64d: Layer already exists 
48078b7e3000: Layer already exists 
fd1e40d7f74b: Layer already exists 
7bb20cf5ef67: Layer already exists 
unsigned: digest: sha256:6de78d896848d68701807ac17396aa565bb29572f9c8f24191ec3b41eececa18 size: 2196

== Step 4: Build & push SIGNED image ==
[+] Building 0.4s (6/6) FINISHED                                                                                                                                                                                                                                         docker:default
 => [internal] load build definition from Dockerfile                                                                                                                                                                                                                               0.0s
 => => transferring dockerfile: 173B                                                                                                                                                                                                                                               0.0s
 => [internal] load metadata for docker.io/library/nginx:alpine                                                                                                                                                                                                                    0.3s
 => [internal] load .dockerignore                                                                                                                                                                                                                                                  0.0s
 => => transferring context: 2B                                                                                                                                                                                                                                                    0.0s
 => [1/2] FROM docker.io/library/nginx:alpine@sha256:8491795299c8e739b7fcc6285d531d9812ce2666e07bd3dd8db00020ad132295                                                                                                                                                              0.0s
 => CACHED [2/2] RUN echo "SIGNED IMAGE" > /usr/share/nginx/html/index.html                                                                                                                                                                                                        0.0s
 => exporting to image                                                                                                                                                                                                                                                             0.0s
 => => exporting layers                                                                                                                                                                                                                                                            0.0s
 => => writing image sha256:f2c5009a9469e8ca10750518e4116c3f805f226091681fbe64a8c931c47beb0d                                                                                                                                                                                       0.0s
 => => naming to docker.io/library/signed:v1                                                                                                                                                                                                                                       0.0s
The push refers to repository [830427153490.dkr.ecr.ap-southeast-1.amazonaws.com/signed-demo-app]
fa1eed4c0d1c: Layer already exists 
e6fe11fa5b7f: Layer already exists 
67ea0b046e7d: Layer already exists 
ed5fa8595c7a: Layer already exists 
8ae63eb1f31f: Layer already exists 
b3e3d1bbb64d: Layer already exists 
48078b7e3000: Layer already exists 
fd1e40d7f74b: Layer already exists 
7bb20cf5ef67: Layer already exists 
signed: digest: sha256:4dc0d9e74f067910df8a982c21afa9ce7aeb2c135bc306a74869cb17074c6b0f size: 2196

== Step 5: Resolve signed image digest ==
✓ Signed image digest: sha256:4dc0d9e74f067910df8a982c21afa9ce7aeb2c135bc306a74869cb17074c6b0f

== Step 6: Install Kyverno ==
"kyverno" has been added to your repositories
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "kyverno" chart repository
Update Complete. ⎈Happy Helming!⎈
NAME: kyverno
LAST DEPLOYED: Tue Jan  6 19:24:08 2026
NAMESPACE: kyverno
STATUS: deployed
REVISION: 1
NOTES:
Chart version: 3.6.1
Kyverno version: v1.16.1

Thank you for installing kyverno! Your release is named kyverno.

The following components have been installed in your cluster:
- CRDs
- Admission controller
- Reports controller
- Cleanup controller
- Background controller


⚠️  WARNING: Setting the admission controller replica count below 2 means Kyverno is not running in high availability mode.


⚠️  WARNING: PolicyExceptions are disabled by default. To enable them, set '--enablePolicyException' to true.

💡 Note: There is a trade-off when deciding which approach to take regarding Namespace exclusions. Please see the documentation at https://kyverno.io/docs/installation/#security-vs-operability to understand the risks.
Waiting for deployment "kyverno-admission-controller" rollout to finish: 0 of 1 updated replicas are available...

deployment "kyverno-admission-controller" successfully rolled out

== Step 7: Apply signed-image-only policy ==
clusterpolicy.kyverno.io/only-signed-image-digest created

== Step 8: Deploy UNSIGNED pod (EXPECTED TO FAIL) ==
Error from server: error when creating "STDIN": admission webhook "validate.kyverno.svc-fail" denied the request: 

resource Pod/default/unsigned-pod was blocked due to the following policies 

only-signed-image-digest:
  allow-only-signed-image: 'validation error: Only SIGNED image digest is allowed.
    rule allow-only-signed-image failed at path /spec/containers/0/image/'

== Step 9: Deploy SIGNED pod ==
pod/signed-pod created
NAME         READY   STATUS              RESTARTS   AGE
signed-pod   0/1     ContainerCreating   0          1s

==============================================
 ✅ DEMO COMPLETE – THIS ONE IS CORRECT
 - Unsigned image: BLOCKED
 - Signed image  : ALLOWED
 - Enforcement  : DIGEST-based
==============================================

$ kubectl get pods signed-pod
NAME         READY   STATUS    RESTARTS   AGE
signed-pod   1/1     Running   0          24s

```