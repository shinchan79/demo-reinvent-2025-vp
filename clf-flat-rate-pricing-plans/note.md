## CloudFront Flat-rate pricing plan là gì?

**CloudFront flat-rate pricing plan** là gói **trả tiền cố định theo tháng cho 1 CloudFront distribution**, trong đó AWS **đóng gói sẵn nhiều dịch vụ** (CDN, WAF, DNS, logs, edge compute…) vào **một mức giá duy nhất**, **không tính phí vượt mức**, kể cả khi có **traffic spike hoặc DDoS**.

**Một distribution – một hóa đơn cố định – không lo bill tăng đột biến.**

---

## Vấn đề AWS đang giải quyết

Với mô hình pay-as-you-go truyền thống:

* Traffic tăng → chi phí tăng theo
* Bot/DDoS → vừa tốn tiền vừa tốn hạ tầng backend
* Phải theo dõi và tối ưu nhiều dịch vụ riêng lẻ: CloudFront, WAF, Route 53, logs, Shield…

Flat-rate pricing plan sinh ra để:

* Cố định chi phí
* Gộp dịch vụ
* Giảm gánh vận hành và rủi ro hóa đơn

---

## Flat-rate plan bao gồm những gì?

Trong **một gói duy nhất**, bạn có sẵn:

* CloudFront CDN (edge cache, HTTP/2, HTTP/3, TLS 1.3…)
* AWS WAF + DDoS protection
  (request bị chặn không tính vào quota)
* Bot management và analytics
* Route 53 DNS (kèm quota DNS)
* CloudWatch Logs ingestion (CloudFront + WAF logs)
* CloudFront Functions + Edge Key-Value Store
* TLS certificate miễn phí (ACM)
* S3 storage credits mỗi tháng

Không cần mua, cấu hình, và theo dõi từng dịch vụ riêng lẻ.

---

## Điểm mạnh cốt lõi

### 1. Không có overage

* Traffic tăng đột biến
* Bot hoặc DDoS flood
* Marketing campaign bất ngờ

→ Không phát sinh thêm tiền.

Nếu vượt allowance quá nhiều:

* AWS không tính thêm tiền
* Nhưng có thể giảm hiệu năng hoặc yêu cầu nâng gói

---

### 2. Quota rõ ràng, dễ kiểm soát

Ví dụ:

| Gói      | Requests/tháng | Data transfer |
| -------- | -------------- | ------------- |
| Free     | 1 triệu        | 100 GB        |
| Pro      | 10 triệu       | 50 TB         |
| Business | 125 triệu      | 50 TB         |
| Premium  | 500 triệu      | 50 TB         |

AWS sẽ:

* Cảnh báo ở 50%, 80%, 100%
* Bạn chủ động nâng gói
* Không có hóa đơn bất ngờ

---

## Khi nào nên dùng?

### Rất phù hợp nếu:

* Website hoặc API public
* Traffic khó dự đoán
* Lo ngại DDoS hoặc bot abuse
* Muốn predictable billing
* Muốn đơn giản hóa vận hành
* Không cần feature edge nâng cao, phức tạp

---

## Nhược điểm và giới hạn

### 1. Không phải distribution nào cũng dùng được

Flat-rate plan **không hỗ trợ** các feature sau:

* Lambda@Edge
* Real-time access logs
* Continuous deployment / staging distribution
* Multi-tenant distribution
* Shield Advanced
* Firewall Manager quản lý WAF

Distribution cũ hoặc cấu hình legacy thường phải chỉnh lại hoặc tạo mới.

---

### 2. Ít linh hoạt hơn pay-as-you-go

* Không bật được toàn bộ feature CloudFront
* Một số use case nâng cao buộc phải quay về pay-as-you-go

AWS đánh đổi:
Giảm linh hoạt để đổi lấy chi phí cố định và vận hành đơn giản.

---

### 3. Không tối ưu cho workload rất lớn và ổn định

* Nếu traffic ổn định, rất lớn, đã tối ưu kỹ
* Pay-as-you-go (kèm discount) đôi khi rẻ hơn

Flat-rate phù hợp nhất cho:

* Traffic khó dự đoán
* Workload nhạy cảm về bảo mật
* Team không muốn theo dõi bill chi tiết

---

### 4. Áp dụng theo distribution, không theo account

* Mỗi distribution là một plan riêng
* Không có khái niệm bật cho toàn bộ account

---

## So sánh nhanh: Flat-rate vs Pay-as-you-go

| Tiêu chí          | Flat-rate           | Pay-as-you-go       |
| ----------------- | ------------------- | ------------------- |
| Chi phí           | Cố định             | Biến động           |
| DDoS / bot spike  | Không tăng tiền     | Tăng tiền           |
| Quản lý           | Đơn giản            | Phức tạp            |
| Linh hoạt feature | Thấp hơn            | Cao hơn             |
| Dự đoán hóa đơn   | Rất dễ              | Khó                 |
| Phù hợp workload  | Public, khó dự đoán | Ổn định, tối ưu sâu |

