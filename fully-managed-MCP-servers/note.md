# Amazon EKS Model Context Protocol (MCP) Server là gì?

**Amazon EKS MCP Server** là một **dịch vụ fully managed do AWS vận hành**, cho phép các **AI assistant** (Amazon Q Developer CLI, Kiro, Cursor, Cline…) **tương tác trực tiếp với EKS cluster và tài nguyên Kubernetes** thông qua **Model Context Protocol (MCP)**.

MCP cung cấp một **giao diện chuẩn hóa** để AI có thể:

* Hiểu **trạng thái thực** của EKS cluster
* Hiểu **Kubernetes resources đang chạy**
* Trả lời chính xác, có ngữ cảnh
* Thực hiện workflow vận hành EKS bằng **ngôn ngữ tự nhiên**

Lưu ý:
Amazon EKS MCP Server hiện đang ở **preview**, tính năng và API có thể thay đổi.

---

## MCP giải quyết vấn đề gì trong EKS?

Trước MCP:

* AI chỉ trả lời dựa trên kiến thức chung về Kubernetes
* Không biết:

  * cluster nào
  * namespace nào
  * pod nào đang lỗi
  * log thực tế ra sao
* Không phân biệt dev / staging / prod

Với EKS MCP Server:

* AI **được cấp quyền truy cập context thật của cluster**
* Truy vấn trực tiếp qua AWS + Kubernetes API
* Mọi câu trả lời đều **bám sát trạng thái hệ thống hiện tại**

---

## EKS MCP Server hoạt động như thế nào?

### Kiến trúc logic

1. AI assistant (Q Developer CLI, Kiro, Cursor, Cline…)
2. **MCP Proxy for AWS** (chạy local)
3. **Amazon EKS MCP Server** (AWS-hosted)
4. AWS APIs + Kubernetes API

### Điểm quan trọng

* Không cài server trong cluster
* Không cài agent trong pod
* Không mở Kubernetes API ra internet
* Xác thực bằng **AWS SigV4**
* Phân quyền bằng **IAM**
* Audit đầy đủ bằng **AWS CloudTrail**

---

## EKS MCP Server dùng để làm gì?

EKS MCP Server cung cấp các nhóm khả năng chính sau.

---

### 1. Quản lý EKS cluster

AI có thể:

* Tạo EKS cluster (nếu bật write mode)
* Áp dụng AWS best practices khi tạo cluster
* Xem trạng thái cluster, node group, add-on

Ví dụ:

```
Show me all EKS clusters and their status
Create a new EKS cluster named demo-cluster with VPC and Auto Mode
```

---

### 2. Quản lý Kubernetes resources

AI có thể:

* Deploy application
* Inspect Deployment, Pod, Service, Namespace
* Xem trạng thái workload

Ví dụ:

```
List all deployments in the production namespace
Show me pods that are not in Running state
```

---

### 3. Troubleshooting và debugging

AI có thể:

* Phân tích pod lỗi
* Truy xuất log theo thời gian
* Xem Kubernetes events
* Tra cứu runbook và EKS troubleshooting guide

Ví dụ:

```
Why is my nginx-ingress-controller pod failing to start?
Show me events related to the failed deployment in staging
Get the logs from the aws-node daemonset in the last 30 minutes
```

---

### 4. Query tài liệu EKS theo ngữ cảnh

AI có thể:

* Tìm kiếm tài liệu EKS liên quan trực tiếp tới lỗi đang gặp
* Áp dụng đúng runbook theo tình huống

Ví dụ:

```
Search the EKS troubleshooting guide for pod networking issues
```

---

AWS chịu trách nhiệm hoàn toàn cho EKS MCP Server:

* Không cần cài đặt
* Không cần update
* Không cần vận hành
* Không cần scale

AWS cung cấp sẵn:

* Automatic updates và patching
* IAM-based access control
* CloudTrail audit logging
* High availability và scalability

---

## Bảo mật và phân quyền

EKS MCP Server **không mặc định có quyền ghi**.

### Quyền MCP chính

* `eks-mcp:InvokeMcp`
* `eks-mcp:CallReadOnlyTool`
* `eks-mcp:CallPrivilegedTool` (chỉ khi bật write)

AWS cung cấp sẵn:

* `AmazonEKSMCPReadOnlyAccess`
* Policy full-access (tùy chọn, rủi ro cao hơn)

Mô hình bảo mật:

* IAM kiểm soát AI làm được gì
* Kubernetes RBAC vẫn giữ nguyên
* Không truyền secret qua prompt
* Không tạo Kubernetes Secret bằng MCP

---

## AI assistant nào dùng được EKS MCP?

Theo tài liệu chính thức:

* Amazon Q Developer CLI
* Kiro
* Cursor
* Cline
* Bất kỳ tool nào hỗ trợ MCP

Tất cả đều phải đi qua **MCP Proxy for AWS**.

---

## Giới hạn và lưu ý

* Preview (chưa GA)
* Write mode có rủi ro nếu cấp quyền quá rộng
* Không dùng MCP để:

  * xử lý secret
  * log dữ liệu nhạy cảm
  * áp YAML không rõ nguồn gốc
