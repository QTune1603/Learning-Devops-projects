# Triển Khai Ứng Dụng Web Java trên Kiến Trúc AWS 3-Tier & Tự Động Hóa CI/CD

Dự án này hướng dẫn chi tiết cách tự động hóa triển khai một ứng dụng web Java (Spring Boot + JSP + JDBC) chạy trên kiến trúc hạ tầng **AWS 3-Tier (3 lớp)** có độ tin cậy và bảo mật cao. Dự án sử dụng **Terraform** để quản lý hạ tầng dưới dạng mã nguồn (IaC), **GitHub Actions** để thiết lập đường ống CI/CD, và tích hợp các giải pháp chất lượng mã nguồn (SonarCloud), quản lý artifact (JFrog Artifactory).

---

## 📐 Sơ Đồ Kiến Trúc Hệ Thống (Architecture)

Kiến trúc 3 lớp được thiết kế để phân tách rõ ràng các vai trò của tài nguyên, đảm bảo an toàn tuyệt đối cho tầng dữ liệu (Database) và tầng xử lý nghiệp vụ (App Server).

```
                      +---------------------------------------+
                      |         Internet / Người Dùng         |
                      +---------------------------------------+
                                          |
                                    (Cổng HTTP: 80)
                                          v
                      +---------------------------------------+
                      | Application Load Balancer (Public ALB)|
                      +---------------------------------------+
                                          |
                        (Định tuyến Port 80 -> Port 8080)
                                          v
+-----------------------------------------------------------------------------+
| Tầng Ứng Dụng (Application Tier) - Private Subnet (Không có IP công cộng)   |
|                                                                             |
|   +-----------------------+              +-----------------------+          |
|   |  EC2 Tomcat Server 1  |              |  EC2 Tomcat Server 2  |          |
|   |  - Java 17 & Spring   |              |  - Java 17 & Spring   |          |
|   |  - App chạy Port 8080 |              |  - App chạy Port 8080 |          |
|   +-----------------------+              +-----------------------+          |
|               ^                                      ^                      |
|               | (Tải gói .war từ S3 bucket)          |                      |
|               +------------------+-------------------+                      |
|                                  |                                          |
|                                  v                                          |
|                      +-----------------------+                              |
|                      |  Amazon S3 Bucket     |                              |
|                      +-----------------------+                              |
+-----------------------------------------------------------------------------+
                                          |
                             (Kết nối MySQL Port 3306)
                                          v
+-----------------------------------------------------------------------------+
| Tầng Dữ Liệu (Data Tier) - Isolated Database Subnet                         |
|                                                                             |
|                      +-----------------------+                              |
|                      |   Amazon RDS MySQL    |                              |
|                      |  (Multi-AZ Failover)  |                              |
|                      +-----------------------+                              |
+-----------------------------------------------------------------------------+
```

### Điểm Nổi Bật của Kiến Trúc
*   **VPC & Subnet Isolation**: Phân vùng mạng rõ ràng. Load Balancer (ALB) nằm ở Public Subnets đón traffic người dùng. Máy chủ ứng dụng (Tomcat) nằm ở Private Subnets. Cơ sở dữ liệu (RDS) nằm tách biệt hoàn toàn ở DB Subnets và không thể truy cập từ Internet.
*   **NAT Gateway**: Giúp các máy chủ ứng dụng ở Private Subnet kết nối mạng ra ngoài để tải thư viện hoặc kết nối API (ví dụ: tải gói `.war` từ S3), nhưng chặn hoàn toàn kết nối trực tiếp từ Internet vào máy chủ.
*   **Auto Scaling Group (ASG)**: Tự động khởi chạy và duy trì số lượng máy chủ ứng dụng (desired: 2) phân bố đều qua 2 Availability Zones (AZs) để đảm bảo tính sẵn sàng cao (High Availability).
*   **Chaining Security Groups**: Thiết lập tường lửa nghiêm ngặt. Chỉ ALB mới có quyền truy cập Port `8080` của Tomcat. Chỉ Tomcat mới có quyền kết nối tới Port `3306` của RDS Database.

---

## 🛠️ Các Công Nghệ Sử Dụng

*   **Hạ Tầng Điện Toán Đám Mây**: Amazon Web Services (VPC, EC2, ALB, ASG, RDS MySQL, S3, IAM, SSM).
*   **Hạ Tầng Dưới Dạng Mã (IaC)**: Terraform (phiên bản `>= 1.0.0`).
*   **Ứng Dụng Phía Backend**: Java 17, Spring Boot (2.7.18), Embedded Tomcat 9, JSP, JDBC, MySQL Connector.
*   **Tự Động Hóa CI/CD**: GitHub Actions, Maven Wrapper.
*   **Công Cụ Quản Lý & Bảo Mật**: SonarCloud (Quét chất lượng code), JFrog Artifactory (Lưu trữ gói build), AWS Systems Manager - SSM Agent (Quản lý và truy cập máy chủ bảo mật không cần SSH key).

---

## 📂 Cấu Trúc Thư Mục Dự Án

```
Terraform-AWS-3tier-architecture/
├── README.md               # Hướng dẫn tổng quan (File này)
├── .github/
│   └── workflows/
│       └── maven-build.yml # Định nghĩa luồng CI/CD của GitHub Actions
├── docs/
│   └── infrastructure_flow_guide.md # Hướng dẫn chi tiết luồng hạ tầng
├── Java-Login-App/         # Mã nguồn ứng dụng Java Spring Boot
│   ├── src/                # File code Java và trang giao diện JSP
│   ├── pom.xml             # Quản lý thư viện phụ thuộc Maven
│   └── README.md           # Tài liệu hướng dẫn build ứng dụng & DB schema
└── infrastructure/         # File cấu hình Terraform để triển khai AWS
    ├── main.tf             # File cấu hình chính gọi các module
    ├── variables.tf        # Định nghĩa các biến đầu vào
    ├── terraform.tfvars    # Giá trị thực tế của các biến (Không đẩy lên Git)
    └── modules/            # Các thư mục chứa tài nguyên nhỏ (vpc, rds, alb, asg, s3, security)
```

---

## 🛠️ Hướng Dẫn Các Bước Triển Khai Thực Tế

### Bước 1: Cấu hình AWS CLI & Cài đặt công cụ
1. Cài đặt **AWS CLI v2** và **Terraform** trên máy tính cục bộ .
2. Cấu hình quyền truy cập AWS CLI:
   ```bash
   aws configure
   ```
   Nhập `AWS Access Key ID`, `AWS Secret Access Key`, và vùng mặc định mong muốn (ví dụ: `ap-southeast-1` - Singapore).

### Bước 2: Biên dịch ứng dụng Java và chuẩn bị Artifact
Để tạo ứng dụng chạy trên kiến trúc AWS, trước tiên cần đóng gói ứng dụng thành file `.war`.
1. Đi tới thư mục chứa ứng dụng:
   ```bash
   cd Java-Login-App
   ```
2. Thực hiện compile và đóng gói (Bỏ qua chạy test để tăng tốc độ):
   ```bash
   # Thiết lập JAVA_HOME trỏ về JDK 17 (nếu máy có nhiều phiên bản Java)
   $env:JAVA_HOME="C:\Program Files\Java\jdk-17"
   .\mvnw.cmd clean package -DskipTests
   ```
3. Sau khi build thành công, file đóng gói sẽ nằm ở `Java-Login-App/target/dptweb-1.0.war`.

### Bước 3: Triển khai Hạ Tầng bằng Terraform
1. Di chuyển vào thư mục hạ tầng:
   ```bash
   cd ../infrastructure
   ```
2. Tạo file cấu hình các biến cục bộ tên là `terraform.tfvars`:
   ```hcl
   environment        = "dev"
   aws_region         = "ap-southeast-1"
   availability_zones = ["ap-southeast-1a", "ap-southeast-1b"]
   vpc_cidr           = "192.168.0.0/16"
   public_subnets     = ["192.168.1.0/24", "192.168.2.0/24"]
   private_subnets    = ["192.168.3.0/24", "192.168.4.0/24"]
   db_username        = "admin"
   db_password        = "YourSuperSecretPassword123!" # Sử dụng mật khẩu mạnh 
   instance_type      = "t3.micro"
   ```
3. Chạy các lệnh khởi tạo và deploy hạ tầng:
   ```bash
   # Khởi tạo Terraform và tải AWS Provider plugins
   terraform init
   
   # Kiểm tra tính hợp lệ của cú pháp cấu hình
   terraform validate
   
   # Xem trước các tài nguyên sẽ được tạo ra trên AWS
   terraform plan
   
   # Khởi chạy quá trình tạo hạ tầng (Tốn khoảng 10-15 phút để tạo RDS)
   terraform apply -auto-approve
   ```
4. Khi quá trình hoàn tất, Terraform sẽ hiển thị URL DNS công cộng của Load Balancer (ALB). Lưu lại đường dẫn này.

### Bước 4: Tải gói ứng dụng lên S3 Bucket
Khi hạ tầng hoàn thành, một S3 Bucket bảo mật đã được tạo. Cần đưa file ứng dụng đã build ở Bước 2 lên đây để EC2 tự động tải về khi khởi động:
```bash
aws s3 cp ../Java-Login-App/target/dptweb-1.0.war s3://<TÊN_S3_BUCKET>/dptweb-1.0.war
```

### Bước 5: Khởi tạo bảng dữ liệu trên RDS MySQL
Ứng dụng Java sử dụng bảng `Employee` trong cơ sở dữ liệu `UserDB`. Do RDS nằm ở Private Subnet, không thể truy cập trực tiếp từ máy tính cục bộ để tạo bảng. Ta sẽ dùng dịch vụ **AWS Systems Manager (SSM)** để thực hiện việc này gián tiếp qua máy chủ EC2:

1. Đăng nhập vào một máy chủ EC2 thông qua SSM Session Manager (Máy chủ đã được gán IAM role `AmazonSSMManagedInstanceCore` để kết nối không cần SSH key).
2. Cài đặt mysql client trên máy ảo:
   ```bash
   sudo yum install -y mariadb
   ```
3. Kết nối vào máy chủ RDS MySQL và khởi tạo cấu trúc bảng dữ liệu:
   ```bash
   mysql -h <ĐƯỜNG_DẪN_ENDPOINT_RDS> -u admin -pYourSuperSecretPassword123! -D UserDB -e "CREATE TABLE IF NOT EXISTS Employee (id int unsigned auto_increment not null, first_name varchar(250), last_name varchar(250), email varchar(250), username varchar(250), password varchar(250), regdate timestamp, primary key (id));"
   ```

---

## 🔍 Những Khó Khăn & Sự Cố Thực Tế Đã Gặp Phải (Troubleshooting)

Trong quá trình thực hiện bài lab này, có một số vấn đề phát sinh rất phổ biến cần lưu ý:

### 1. Lỗi Xung đột Thư viện JSP compile (NoSuchMethodError - HTTP 500)
*   **Triệu chứng**: Ứng dụng chạy trên cổng 8080 thành công nhưng khi người dùng gửi yêu cầu truy cập trang đăng nhập, server trả về lỗi `HTTP 500 Internal Server Error`. Nhật ký logs báo lỗi `java.lang.NoSuchMethodError` liên quan tới `UDecoder` hoặc `JreCompat`.
*   **Nguyên nhân**: File `pom.xml` cấu hình cứng thư viện `tomcat-jasper` ở phiên bản cũ `9.0.31`. Trong khi đó, Spring Boot 2.7.18 tự động kéo về bản `tomcat-embed-core` phiên bản `9.0.83` mới hơn. Sự lệch pha này gây ra lỗi nạp lớp (Class Loading) khi biên dịch các trang JSP động.
*   **Khắc phục**: Chuyển đổi thư viện biên dịch trong `pom.xml` từ `tomcat-jasper` thành `tomcat-embed-jasper` và xóa hẳn phiên bản định sẵn. Spring Boot sẽ tự động quản lý đồng bộ và đồng nhất mọi thư viện Tomcat ở phiên bản `9.0.83`.

### 2. Lỗi Target Group Health Check Thất Bại do Spring Security (HTTP 401)
*   **Triệu chứng**: Sau khi sửa xong lỗi 500, máy chủ ứng dụng hoạt động tốt nhưng Load Balancer (ALB) liên tục đánh dấu máy chủ ở trạng thái **Unhealthy** với mã lỗi `ResponseCodeMismatch: [401]`. Kết quả là người dùng không thể truy cập qua URL của ALB (Lỗi 502 Bad Gateway).
*   **Nguyên nhân**: Dự án nạp thư viện `spring-boot-starter-security` mặc định. Bộ lọc bảo mật này tự động bảo vệ tất cả đường dẫn (bao gồm cả `/`), bắt buộc phải có tài khoản đăng nhập và trả về mã `401 Unauthorized` cho các request chưa xác thực. Cấu hình mặc định của ALB Target Group chỉ chấp nhận các mã `200` hoặc `302` là máy chủ khỏe mạnh.
*   **Khắc phục**: 
    1.  Tạo thêm file cấu hình [SecurityConfig.java](file:///E:/DevOps-projects/Terraform-AWS-3tier-architecture/Java-Login-App/src/main/java/com/dpt/demo/SecurityConfig.java) để tắt tính năng lọc CSRF và mở quyền truy cập tự do (`permitAll()`) cho mọi request, nhường quyền kiểm tra tài khoản lại cho database JDBC.
    2.  Cập nhật thuộc tính kiểm tra sức khỏe của Target Group trong file `alb/main.tf` để chấp nhận thêm mã phản hồi `401`:
        ```hcl
        matcher = "200,302,401"
        ```

### 3. Lỗi Trùng Tên Target Group khi thực hiện Recreate tài nguyên
*   **Triệu chứng**: Khi cập nhật cấu hình cổng của Target Group từ `80` sang `8080`, chạy lệnh `terraform apply` báo lỗi API từ AWS: *"ELBv2 Target Group already exists"*.
*   **Nguyên nhân**: Theo mặc định, Terraform sẽ thực hiện tạo tài nguyên mới trước rồi mới xóa tài nguyên cũ (`create_before_destroy`). Vì chúng ta đặt tên cứng `name = "dev-tg"` nên khi tạo tài nguyên mới, AWS báo lỗi vì đã có một Target Group trùng tên đang tồn tại.
*   **Khắc phục**: Thay đổi thuộc tính đặt tên của Target Group thành `name = "${var.environment}-tg-8080"`. Việc đổi tên này giúp Terraform khởi tạo thành công tài nguyên mới trước khi gỡ bỏ cái cũ mà không bị lỗi trùng tên.

---

## 🧪 Quy Trình Kiểm Thử Hệ Thống (E2E Testing)

Sau khi máy chủ ở trạng thái **Healthy**, hãy mở trình duyệt lên và kiểm tra:

1.  **Đăng ký tài khoản mới**:
    *   Truy cập link: `http://<ALB-DNS-Name>/register`
    *   Điền thông tin tài khoản (ví dụ: Username: `qitune`, Password: `123456`) và nhấn **Submit**.
    *   Thông báo hiển thị thành công: *"user account has been added for qitune"*.
2.  **Đăng nhập và kiểm tra dữ liệu**:
    *   Truy cập link: `http://<ALB-DNS-Name>/login`
    *   Nhập tài khoản vừa tạo.
    *   Sau khi đăng nhập thành công, sẽ được điều hướng vào Dashboard hiển thị lời chào kèm địa chỉ Email đăng ký: *"Welcome qitune@gmail.com"*. Điều này xác nhận ứng dụng đã truy vấn dữ liệu từ **RDS MySQL** thành công!

---

## 🛑 Dọn Dẹp Tài Nguyên Để Tránh Mất Phí AWS (Cực kỳ quan trọng)

> [!WARNING]
> Vì dự án có sử dụng **Auto Scaling Group (ASG)** để tự động quản lý số lượng máy chủ, **không thể tắt máy chủ EC2 một cách thủ công** trên AWS Console. Nếu làm vậy, ASG sẽ tự động coi máy ảo đó bị lỗi và lập tức tạo ra máy ảo mới để thay thế, dẫn tới tiếp tục phát sinh chi phí.

Để xóa bỏ hoàn toàn tất cả các tài nguyên đã tạo trên AWS khi không còn nhu cầu học tập, hãy di chuyển tới thư mục `infrastructure/` trên terminal máy và chạy lệnh duy nhất sau:

```bash
# Di chuyển vào thư mục hạ tầng
cd infrastructure

# Hủy bỏ toàn bộ hạ tầng đã tạo tự động
terraform destroy -auto-approve
```
Quá trình này sẽ tốn khoảng 5–10 phút để dọn dẹp sạch sẽ tài khoản free tier, đưa chi phí AWS về mức an toàn.
