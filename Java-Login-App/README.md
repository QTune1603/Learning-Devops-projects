# Java Login Application

This is a sample Java Login application designed to demonstrate backend configuration, database connection, and deployment onto Apache Tomcat web servers.

---

## Database Configuration

The application connects to a MySQL database to manage and authenticate employee login details. The default database schema name is `UserDB`.

### SQL Setup Scripts

You can initialize your MySQL database (either locally or on your AWS RDS instance) using the following SQL commands:

#### 1. Create and Connect to the Database
```sql
-- View existing databases
SHOW DATABASES;

-- Create the database
CREATE DATABASE UserDB;

-- Connect to the newly created database
USE UserDB;
```

#### 2. Create the Users Table
Below is the table schema to store employee login information:
```sql
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) NOT NULL,
    role VARCHAR(20) DEFAULT 'employee',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 3. Verify Table Creation
```sql
-- List tables in UserDB
SHOW TABLES;

-- Show the structure of the users table
DESCRIBE users;
```

#### 4. Insert Test Data
You can insert a sample user to test the login functionality:
```sql
INSERT INTO users (username, password, email, role) 
VALUES ('admin', 'admin123', 'admin@example.com', 'admin');
```

---

## Building the Application

The application is structured as a standard Maven project. To compile and package the application into a deployable `.war` (Web Application Archive) file:

### Prerequisites
- JDK 11 installed
- Apache Maven installed

### Packaging Commands
Run the following command in this directory:
```bash
# Clean previous builds and package the app
mvn clean package
```

This will compile the Java classes and generate the `.war` package under the `target/` directory (e.g., `target/Java-Login-App.war`), which can then be deployed to your Tomcat server.
