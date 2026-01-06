### So sánh NLB Weighted vs ALB Canary vs Istio Traffic Shifting

| Tiêu chí                  | NLB Weighted Target Groups | ALB Canary (Weighted Forward) | Istio Traffic Shifting              |
| ------------------------- | -------------------------- | ----------------------------- | ----------------------------------- |
| Tầng hoạt động            | L4 (TCP/UDP)               | L7 (HTTP/HTTPS)               | L7+ (Service Mesh)                  |
| Hiểu HTTP                 | Không                      | Có                            | Có                                  |
| Hỗ trợ TCP / non-HTTP     | Có                         | Không                         | Hạn chế (qua sidecar)               |
| Cơ chế phân luồng         | Phân phối connection/flow  | Phân phối request             | Phân phối request                   |
| Điều khiển theo trọng số  | Có (0–999)                 | Có (%)                        | Có (%)                              |
| Canary theo header        | Không                      | Hạn chế                       | Có                                  |
| Canary theo cookie / user | Không                      | Hạn chế                       | Có                                  |
| Path-based routing        | Không                      | Có                            | Có                                  |
| Retry                     | Không                      | Không                         | Có                                  |
| Circuit breaking          | Không                      | Không                         | Có                                  |
| Fault injection           | Không                      | Không                         | Có                                  |
| Stickiness                | Có (TCP level)             | Có (HTTP cookie)              | Có                                  |
| Observability             | Gần như không              | Cơ bản (ALB metrics)          | Rất chi tiết (trace, metrics, logs) |
| Latency overhead          | Rất thấp                   | Thấp                          | Cao                                 |
| Resource overhead         | Rất thấp                   | Thấp                          | Cao                                 |
| Độ phức tạp vận hành      | Thấp                       | Trung bình                    | Cao                                 |
| Yêu cầu thay đổi ứng dụng | Không                      | Không                         | Không (nhưng cần sidecar)           |
| Phù hợp EKS Auto Mode     | Có                         | Có                            | Không khuyến nghị                   |
| Phù hợp Blue/Green        | Có                         | Có                            | Có                                  |
| Phù hợp Canary tinh vi    | Không                      | Hạn chế                       | Có                                  |
| Chi phí vận hành          | Thấp                       | Trung bình                    | Cao                                 |
| Đối tượng phù hợp         | Infra / Platform đơn giản  | Web / API team                | Platform / SRE team lớn             |

---

| Trường hợp                                   | Nên dùng     |
| -------------------------------------------- | ------------ |
| Canary hạ tầng, TCP, gRPC, zero overhead     | NLB Weighted |
| Canary HTTP đơn giản, dễ vận hành            | ALB Canary   |
| Canary/A-B testing phức tạp, policy nâng cao | Istio        |


```
AWSReservedSSO_AWSAdministratorAccess_4288b0790c6df772:~/environment/VPB-reinvent-recap-demos/demo-reinvent-2025-vp/nlb-weighted-targed-groups (main) $ ./demo.sh 
==============================================
 NLB Weighted Target Groups Demo (REAL)
 Cluster : test-cluster
 Region  : ap-southeast-1
==============================================
== 0. Update kubeconfig ==
Updated context arn:aws:eks:ap-southeast-1:830427153490:cluster/test-cluster in /home/ec2-user/.kube/config
== 1. Patch Kyverno (exclude demo namespace) ==
clusterpolicy.kyverno.io/only-signed-image-digest patched (no change)
== 2. Recreate namespace ==
namespace/weighted-demo created
== 3. Deploy app v1 (BLUE) ==
deployment.apps/app-v1 created
service/svc-v1 created
== 4. Deploy app v2 (GREEN) ==
deployment.apps/app-v2 created
service/svc-v2 created
== 5. Wait for pods ==
Waiting for deployment "app-v1" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "app-v1" rollout to finish: 1 of 2 updated replicas are available...
deployment "app-v1" successfully rolled out
deployment "app-v2" successfully rolled out
== 6. Create NLB Service (shared) ==
service/nlb-entry created
== 7. Wait for NLB ==
NLB DNS: k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com

=================================================
 IMPORTANT:
 Kubernetes DOES NOT control weighted routing.
 Weights MUST be configured on NLB listener:

 aws elbv2 modify-listener \
   --listener-arn <listener-arn> \
   --default-actions '[{"Type":"forward","ForwardConfig":{"TargetGroups":[
     {"TargetGroupArn":"<tg-v1>","Weight":80},
     {"TargetGroupArn":"<tg-v2>","Weight":20}
   ]}}]'

 Test:
 curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
 ```


```
sh-5.2$ curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
V2 GREEN
sh-5.2$ curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
V1 BLUE
sh-5.2$ curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
V2 GREEN
sh-5.2$ curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
V1 BLUE
sh-5.2$ curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
V2 GREEN
sh-5.2$ curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
V2 GREEN
sh-5.2$ curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
V1 BLUE
sh-5.2$ curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
V2 GREEN
sh-5.2$ curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
V2 GREEN
sh-5.2$ curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
V2 GREEN
sh-5.2$ curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
V2 GREEN
sh-5.2$ curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
V1 BLUE
sh-5.2$ curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
V1 BLUE
sh-5.2$ curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
V1 BLUE
sh-5.2$ curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
V2 GREEN
sh-5.2$ curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
V2 GREEN
sh-5.2$ curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
V1 BLUE
sh-5.2$ curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
V1 BLUE
sh-5.2$ curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
V1 BLUE
sh-5.2$ curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
V1 BLUE
sh-5.2$ curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
V1 BLUE
sh-5.2$ curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
V2 GREEN
sh-5.2$ curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
V1 BLUE
sh-5.2$ curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
V2 GREEN
sh-5.2$ curl http://k8s-weighted-nlbentry-e23bf182c5-0a3ef019a4681023.elb.ap-southeast-1.amazonaws.com
V1 BLUE
```

