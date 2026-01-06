```
$ ./demo-provisioned-controlplane.sh 
=================================================
 EKS Provisioned Control Plane Demo
 Cluster: test-cluster
=================================================

1. Checking current control plane tier...
{
    "tier": "standard"
}

2. Freezing Karpenter (prevent node eviction)...
✓ Karpenter not found, skipping

3. Ensuring metrics-server is installed...
Waiting for metrics-server...
NAME                  CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
i-01ffce9781491f99e   2001m        112%     850Mi           27%         
i-0eb72f78a3d0ccede   2000m        112%     1360Mi          49%         

4. Preparing load test namespace...
namespace/load-test unchanged

5. Deploying API server stress job...
job.batch/apiserver-stress unchanged

6. Waiting for load to ramp up...

7. Capturing API server metrics...
✓ Metrics saved to /tmp/apiserver-metrics-1767726485.txt

8. Key control plane indicators:
-------------------------------------------------
Inflight requests:
# HELP apiserver_current_inflight_requests [STABLE] Maximal number of currently used inflight request limit of this apiserver per request kind in last second.
# TYPE apiserver_current_inflight_requests gauge
apiserver_current_inflight_requests{request_kind="mutating"} 1
apiserver_current_inflight_requests{request_kind="readOnly"} 1

Request throttling:
✓ No throttling detected

Latency buckets (p99 indicator):
apiserver_request_duration_seconds_bucket{component="apiserver",dry_run="",group="wafv2.services.k8s.aws",resource="webacls",scope="cluster",subresource="",verb="WATCH",version="v1alpha1",le="20"} 1
apiserver_request_duration_seconds_bucket{component="apiserver",dry_run="",group="wafv2.services.k8s.aws",resource="webacls",scope="cluster",subresource="",verb="WATCH",version="v1alpha1",le="30"} 1
apiserver_request_duration_seconds_bucket{component="apiserver",dry_run="",group="wafv2.services.k8s.aws",resource="webacls",scope="cluster",subresource="",verb="WATCH",version="v1alpha1",le="45"} 1
apiserver_request_duration_seconds_bucket{component="apiserver",dry_run="",group="wafv2.services.k8s.aws",resource="webacls",scope="cluster",subresource="",verb="WATCH",version="v1alpha1",le="60"} 1
apiserver_request_duration_seconds_bucket{component="apiserver",dry_run="",group="wafv2.services.k8s.aws",resource="webacls",scope="cluster",subresource="",verb="WATCH",version="v1alpha1",le="+Inf"} 1
-------------------------------------------------

9. Job status:
NAME               STATUS    COMPLETIONS   DURATION   AGE
api-load-test      Failed    0/500         33m        33m
apiserver-stress   Running   0/800         6m19s      6m19s

10. Node status (should remain stable):
NAME                  STATUS   ROLES    AGE    VERSION
i-01ffce9781491f99e   Ready    <none>   32m    v1.34.2-eks-b3126f4
i-0eb72f78a3d0ccede   Ready    <none>   6m7s   v1.34.2-eks-b3126f4

=================================================
 Demo step complete.
 Now repeat this script after upgrading tier
 (standard -> tier-xl) and compare metrics.
=================================================


$ ./demo-provisioned-controlplane.sh 
=================================================
 EKS Provisioned Control Plane Demo (HARD LOAD)
 Cluster: test-cluster
=================================================

1. Checking current control plane tier...
{
    "tier": "standard"
}

2. Freezing Karpenter (prevent node eviction)...
✓ Karpenter not found, skipping

3. Ensuring metrics-server is installed...
Waiting for metrics-server...
NAME                  CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
i-01ffce9781491f99e   2001m        112%     805Mi           25%         
i-0eb72f78a3d0ccede   2001m        112%     1355Mi          49%         

4. Preparing load test namespace...
namespace/load-test unchanged

5. Cleaning up previous stress jobs...
job.batch "api-load-test" deleted from load-test namespace
job.batch "apiserver-stress" deleted from load-test namespace
configmap "kube-root-ca.crt" deleted from load-test namespace

6. Deploying HARD API server stress job...
job.batch/apiserver-stress-hard created

7. Waiting for load to ramp up...

8. Capturing API server metrics...
✓ Metrics saved to /tmp/apiserver-metrics-1767726853.txt

9. Key control plane indicators:
-------------------------------------------------
Inflight requests:
# HELP apiserver_current_inflight_requests [STABLE] Maximal number of currently used inflight request limit of this apiserver per request kind in last second.
# TYPE apiserver_current_inflight_requests gauge
apiserver_current_inflight_requests{request_kind="mutating"} 2
apiserver_current_inflight_requests{request_kind="readOnly"} 2

Request throttling:
✓ No throttling detected

Latency buckets (look for high buckets):
apiserver_request_duration_seconds_bucket{component="apiserver",dry_run="",group="wafv2.services.k8s.aws",resource="webacls",scope="cluster",subresource="",verb="WATCH",version="v1alpha1",le="5"} 3
apiserver_request_duration_seconds_bucket{component="apiserver",dry_run="",group="wafv2.services.k8s.aws",resource="webacls",scope="cluster",subresource="",verb="WATCH",version="v1alpha1",le="6"} 3
apiserver_request_duration_seconds_bucket{component="apiserver",dry_run="",group="wafv2.services.k8s.aws",resource="webacls",scope="cluster",subresource="",verb="WATCH",version="v1alpha1",le="8"} 3
apiserver_request_duration_seconds_bucket{component="apiserver",dry_run="",group="wafv2.services.k8s.aws",resource="webacls",scope="cluster",subresource="",verb="WATCH",version="v1alpha1",le="10"} 3
apiserver_request_duration_seconds_bucket{component="apiserver",dry_run="",group="wafv2.services.k8s.aws",resource="webacls",scope="cluster",subresource="",verb="WATCH",version="v1alpha1",le="15"} 3
apiserver_request_duration_seconds_bucket{component="apiserver",dry_run="",group="wafv2.services.k8s.aws",resource="webacls",scope="cluster",subresource="",verb="WATCH",version="v1alpha1",le="20"} 3
apiserver_request_duration_seconds_bucket{component="apiserver",dry_run="",group="wafv2.services.k8s.aws",resource="webacls",scope="cluster",subresource="",verb="WATCH",version="v1alpha1",le="30"} 3
apiserver_request_duration_seconds_bucket{component="apiserver",dry_run="",group="wafv2.services.k8s.aws",resource="webacls",scope="cluster",subresource="",verb="WATCH",version="v1alpha1",le="45"} 3
apiserver_request_duration_seconds_bucket{component="apiserver",dry_run="",group="wafv2.services.k8s.aws",resource="webacls",scope="cluster",subresource="",verb="WATCH",version="v1alpha1",le="60"} 3
apiserver_request_duration_seconds_bucket{component="apiserver",dry_run="",group="wafv2.services.k8s.aws",resource="webacls",scope="cluster",subresource="",verb="WATCH",version="v1alpha1",le="+Inf"} 3
-------------------------------------------------

10. Job status:
NAME                    STATUS    COMPLETIONS   DURATION   AGE
apiserver-stress-hard   Running   0/1500        42s        42s

11. Node status (node pressure is OK for demo):
NAME                  STATUS   ROLES    AGE   VERSION
i-01ffce9781491f99e   Ready    <none>   39m   v1.34.2-eks-b3126f4
i-035559f3b4b840e34   Ready    <none>   27s   v1.34.2-eks-b3126f4
i-0cfd74bb4188ec461   Ready    <none>   29s   v1.34.2-eks-b3126f4
i-0eb72f78a3d0ccede   Ready    <none>   12m   v1.34.2-eks-b3126f4

=================================================
 Demo step complete.
 If STANDARD shows high inflight / latency,
 upgrade to tier-XL and re-run THIS SAME SCRIPT.
=================================================
```

At this scale, Standard still works.
Provisioned Control Plane is about guaranteed headroom, not fixing a problem.