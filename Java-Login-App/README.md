# Java Login Application & Database Guide

This guide details the structure of the Java web application, its database schema, and how to compile, deploy, and verify the application.

---

## 🛠️ Build Prerequisites

*   **Java Development Kit (JDK)**: Version **17** is required to run the Spring Boot application (configured with Tomcat 9 embedded).
*   **Maven**: The project includes the Maven Wrapper (`mvnw` / `mvnw.cmd`), so there is no need to install Maven separately.

---

## 📦 Local Compilation & Packaging

To compile the source code and build the deployable `.war` archive, run the following command in the `Java-Login-App/` directory:

### On Windows (PowerShell/CMD):
```powershell
$env:JAVA_HOME="C:\Program Files\Java\jdk-17" # Point to your JDK 17 installation path
.\mvnw.cmd clean package -DskipTests
```

### On Linux/macOS:
```bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk # Point to your JDK 17 installation path
chmod +x mvnw
./mvnw clean package -DskipTests
```

The compiled binary will be generated at:
`Java-Login-App/target/dptweb-1.0.war`

---

## 🗄️ Database Setup (RDS MySQL)

The application communicates with a MySQL database named `UserDB`. Since it uses raw JDBC queries (`DriverManager.getConnection`), the required database tables must be created manually before running the application.

Execute the following SQL commands on your MySQL / RDS instance:

```sql
-- 1. Create the database (if not created automatically)
CREATE DATABASE IF NOT EXISTS UserDB;

-- 2. Use the database
USE UserDB;

-- 3. Create the Employee table to store credentials
CREATE TABLE IF NOT EXISTS Employee (
  id INT UNSIGNED AUTO_INCREMENT NOT NULL,
  first_name VARCHAR(250),
  last_name VARCHAR(250),
  email VARCHAR(250),
  username VARCHAR(250),
  password VARCHAR(250),
  regdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
);
```

---

## 🔒 Security Configuration

The application includes `spring-boot-starter-security` in its dependencies. By default, Spring Security restricts all pages, generates a random admin password, and blocks custom POST forms with CSRF exceptions.

To let our custom JDBC-backed login controllers work, we added **[SecurityConfig.java](src/main/java/com/dpt/demo/SecurityConfig.java)**:
*   Disables CSRF protection (allowing raw form submissions from JSP).
*   Allows all requests (`permitAll()`) so the custom login controllers in `login.java` and `register.java` can process authentication checks against RDS.

---

## 🧪 Testing and Verification Steps

Once the infrastructure is active and the Application Load Balancer (ALB) is running, you can test the login and registration flows as follows:

### Step 1: User Registration
1.  Navigate to the **Register Page**:
    `http://<ALB-DNS-Name>/register`
2.  Fill out the form (First Name, Last Name, Email, Username, Password).
3.  Click **Submit**.
    *   *Backend Action: The application connects to RDS MySQL, executes an `INSERT INTO Employee` query, and registers the user.*
    *   *Result: You will see a success message: `"user account has been added for <username>"`.*

### Step 2: User Authentication
1.  Navigate to the **Login Page**:
    `http://<ALB-DNS-Name>/login`
2.  Enter the registered **Username** and **Password** (e.g., `123456` or whatever you registered).
3.  Click **Login**.
    *   *Backend Action: The application executes `SELECT * FROM Employee WHERE username = ... AND password = ...` against RDS.*
    *   *Result: Upon successful authentication, you will be redirected to the user dashboard showing a personalized welcome message: `"Welcome <email>"`.*