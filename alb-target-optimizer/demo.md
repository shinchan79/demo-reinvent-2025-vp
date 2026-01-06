“Target Optimizer không phải traffic splitting,
nó là backpressure control – ALB chỉ gửi request khi target báo sẵn sàng.”

```
kubectl logs -n target-opt-demo deploy/demo -c optimizer-agent
```

## So sánh Target Optimizer vs HPA vs Istio (Concurrency Control)

| Tiêu chí                       | **ALB Target Optimizer**                   | **Kubernetes HPA**           | **Istio (Envoy / Mesh)**     |
| ------------------------------ | ------------------------------------------ | ---------------------------- | ---------------------------- |
| Lớp hoạt động                  | Load Balancer (L7 ALB)                     | Orchestrator (control plane) | Service Mesh (data plane)    |
| Kiểm soát concurrency **thực** | **Có – cứng** (hard limit)                 | **Không**                    | **Có – cứng / mềm**          |
| Cách giới hạn                  | ALB chỉ gửi request khi agent báo sẵn sàng | Scale replica theo metric    | Envoy limit / queue / reject |
| Đơn vị giới hạn                | Per-target (instance / pod IP)             | Pod replica                  | Pod / service / route        |
| Enforcement location           | **Trước khi request vào pod**              | Sau khi pod quá tải          | Trong sidecar trước app      |
| Backpressure thật              | **Có** (ALB chờ / không gửi)               | **Không** (app tự chết)      | **Có**                       |
| Phản ứng khi quá tải           | ALB không gửi thêm request                 | App overload → 5xx           | Queue / 429 / shed           |
| Thời gian phản ứng             | **Milliseconds**                           | **Seconds → minutes**        | Milliseconds                 |
| Phụ thuộc metric               | Không                                      | CPU / memory / custom        | Không (runtime)              |
| Phụ thuộc traffic pattern      | Không                                      | Có                           | Không                        |
| Cần agent / sidecar            | **Có (agent riêng)**                       | Không                        | **Có (Envoy)**               |
| Yêu cầu sửa app                | Không                                      | Không                        | Không                        |
| Phù hợp EKS thuần              | **Rất phù hợp**                            | Mặc định                     | Phức tạp                     |
| Độ phức tạp vận hành           | Trung bình                                 | Thấp                         | **Rất cao**                  |
| Phù hợp prod scale lớn         | Có                                         | Có                           | Có (đội lớn)                 |
| Chi phí vận hành               | Thấp                                       | Thấp                         | Cao                          |
| Phù hợp canary / rollout       | Không                                      | Không                        | **Rất mạnh**                 |
| AWS-native                     | **100%**                                   | 100%                         | Không                        |
| Multi-cloud                    | Không                                      | Có                           | Có                           |

---

### 1. **Target Optimizer**

* Giải quyết **đúng một bài toán**:
  **“Pod chỉ nhận N request cùng lúc, không hơn”**
* Load balancer **chủ động dừng gửi traffic**
* **Không scale**, chỉ bảo vệ
* Lý tưởng cho:

  * hệ thống legacy
  * app dễ nghẽn
  * backend không chịu được burst

---

### 2. **HPA**

* **Không kiểm soát concurrency**
* Chỉ **chữa hậu quả**, không chặn nguyên nhân
* Scale **chậm**, reactive
* Phù hợp:

  * workload ổn định
  * scale dài hạn
  * không phù hợp burst ngắn

---

### 3. **Istio (Envoy)**

* **Giải pháp toàn diện nhất**
* Kiểm soát:

  * concurrency
  * rate limit
  * queue
  * circuit breaker
* Đổi lại:

  * nặng
  * phức tạp
  * vận hành tốn người

---

| Tình huống                           | Nên dùng         |
| ------------------------------------ | ---------------- |
| Burst traffic ngắn                   | Target Optimizer |
| App dễ nghẽn, không sửa code         | Target Optimizer |
| Auto scale dài hạn                   | HPA              |
| Canary / A/B / progressive delivery  | Istio            |
| Đội nhỏ, EKS thuần                   | Target Optimizer |
| Multi-cloud, traffic policy phức tạp | Istio            |
| Muốn “chặn từ cửa”                   | Target Optimizer |
| Muốn “điều tiết bên trong”           | Istio            |

```
AWSReservedSSO_AWSAdministratorAccess_4288b0790c6df772:~/environment/VPB-reinvent-recap-demos/demo-reinvent-2025-vp/alb-target-optimizer (main) $ ./demo.sh 
==============================================
 ALB TARGET OPTIMIZER – FULL REAL DEMO
 Cluster : test-cluster
 Region  : ap-southeast-1
==============================================
== 0. Update kubeconfig ==
Updated context arn:aws:eks:ap-southeast-1:830427153490:cluster/test-cluster in /home/ec2-user/.kube/config
== 1. Patch Kyverno (exclude demo namespace) ==
clusterpolicy.kyverno.io/only-signed-image-digest patched (no change)
== 2. Recreate namespace ==
namespace "target-opt-demo" deleted
namespace/target-opt-demo created
== 3. Deploy APP + TARGET OPTIMIZER AGENT ==
deployment.apps/demo created
Waiting for deployment "demo" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "demo" rollout to finish: 1 of 2 updated replicas are available...
deployment "demo" successfully rolled out
== 4. Collect Pod IPs ==
Pod IPs: 10.0.100.206 10.0.100.205
== 5. Create Target Group (TARGET OPTIMIZER ENABLED) ==
TargetGroup ARN: arn:aws:elasticloadbalancing:ap-southeast-1:830427153490:targetgroup/target-opt-tg/35bfa36433503c98
== 6. Register Pod IPs as targets ==
== 7. Create Security Group for ALB ==
{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-043497da1f8703dec",
            "GroupId": "sg-0217563711e3cf059",
            "GroupOwnerId": "830427153490",
            "IsEgress": false,
            "IpProtocol": "tcp",
            "FromPort": 80,
            "ToPort": 80,
            "CidrIpv4": "0.0.0.0/0",
            "SecurityGroupRuleArn": "arn:aws:ec2:ap-southeast-1:830427153490:security-group-rule/sgr-043497da1f8703dec"
        }
    ]
}
== 8. Create PUBLIC ALB ==
== 9. Create Listener ==
{
    "Listeners": [
        {
            "ListenerArn": "arn:aws:elasticloadbalancing:ap-southeast-1:830427153490:listener/app/target-opt-alb/0abd889bb0a9682b/05569ab93997af9f",
            "LoadBalancerArn": "arn:aws:elasticloadbalancing:ap-southeast-1:830427153490:loadbalancer/app/target-opt-alb/0abd889bb0a9682b",
            "Port": 80,
            "Protocol": "HTTP",
            "DefaultActions": [
                {
                    "Type": "forward",
                    "TargetGroupArn": "arn:aws:elasticloadbalancing:ap-southeast-1:830427153490:targetgroup/target-opt-tg/35bfa36433503c98",
                    "ForwardConfig": {
                        "TargetGroups": [
                            {
                                "TargetGroupArn": "arn:aws:elasticloadbalancing:ap-southeast-1:830427153490:targetgroup/target-opt-tg/35bfa36433503c98",
                                "Weight": 1
                            }
                        ],
                        "TargetGroupStickinessConfig": {
                            "Enabled": false
                        }
                    }
                }
            ]
        }
    ]
}
== 10. Fetch ALB DNS ==
==============================================
 ALB READY
 URL: http://target-opt-alb-713455394.ap-southeast-1.elb.amazonaws.com
==============================================

TEST:
  ab -n 50 -c 20 http://target-opt-alb-713455394.ap-southeast-1.elb.amazonaws.com/

WATCH METRICS:
  TargetControlActiveChannelCount
  TargetControlRequestRejectCount
```

```
$ ab -n 50 -c 20 http://target-opt-alb-713455394.ap-southeast-1.elb.amazonaws.com/
This is ApacheBench, Version 2.3 <$Revision: 1923142 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking target-opt-alb-713455394.ap-southeast-1.elb.amazonaws.com (be patient).....done


Server Software:        
Server Hostname:        target-opt-alb-713455394.ap-southeast-1.elb.amazonaws.com
Server Port:            80

Document Path:          /
Document Length:        19 bytes

Concurrency Level:      20
Time taken for tests:   0.012 seconds
Complete requests:      50
Failed requests:        0
Non-2xx responses:      50
Total transferred:      7850 bytes
HTML transferred:       950 bytes
Requests per second:    4220.48 [#/sec] (mean)
Time per request:       4.739 [ms] (mean)
Time per request:       0.237 [ms] (mean, across all concurrent requests)
Transfer rate:          647.08 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    1   0.2      1       1
Processing:     1    3   0.9      3       4
Waiting:        1    3   0.9      3       4
Total:          2    3   1.0      3       5

Percentage of the requests served within a certain time (ms)
  50%      3
  66%      4
  75%      4
  80%      5
  90%      5
  95%      5
  98%      5
  99%      5
 100%      5 (longest request)
 ```