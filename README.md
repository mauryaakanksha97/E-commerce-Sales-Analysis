# E-Commerce-Sales-Performance-Analysis

## 📌 Project Overview
This project presents an end-to-end E-commerce Sales Analysis solution built using MySQL. The objective of this project is to analyze business performance, customer transactions, product categories, and profitability using structured SQL queries and relational database concepts.

The project demonstrates practical implementation of:
- Relational Database Design
- Data Import & Cleaning
- SQL Query Optimization
- Business KPI Analysis
- Data Validation & Integrity Checks
- Analytical Reporting using SQL Views

---

## 🎯 Objectives
- Analyze overall sales and profit performance
- Track category-wise business growth
- Evaluate customer and order behavior
- Compare monthly sales against targets
- Identify loss-making transactions
- Build reusable analytical SQL views

---

## 🛠️ Tools & Technologies
- MySQL Workbench
- SQL
- CSV Datasets
- Relational Database Management System (RDBMS)

---

## 🗂️ Database Schema

### 1️⃣ order_list
Contains customer and order information.
- Order ID
- Order Date
- Customer Name
- State
- City

### 2️⃣ order_details
Contains transactional sales details.
- Order ID
- Amount
- Profit
- Quantity
- Category
- Sub-Category
- Payment Mode

### 3️⃣ sales_target
Contains monthly category-wise target data.
- Month of Order Date
- Category
- Target

---

## ⚙️ Key Features Implemented

### ✅ Database Design
- Created normalized relational tables
- Applied Primary Key & Foreign Key relationships
- Maintained referential integrity

### ✅ Data Import & Validation
- Imported CSV datasets into MySQL
- Performed data cleaning and validation
- Checked for:
  - Null values
  - Duplicate records
  - Orphan rows
  - Foreign key mismatches

### ✅ SQL Analysis Performed
- Total Revenue Analysis
- Profit Analysis
- Category-wise Sales
- State-wise Performance
- Monthly Sales Trends
- Sales vs Target Comparison
- Loss-making Order Detection
- KPI Calculations

### ✅ Advanced SQL Concepts Used
- JOINs
- GROUP BY
- Aggregate Functions
- CASE Statements
- Views
- Data Validation Queries

---

## 📊 Sample Business Insights
- Identified top-performing product categories
- Evaluated monthly business growth trends
- Detected low-profit and loss-making transactions
- Compared actual sales with business targets
- Analyzed geographical sales distribution

---

## 📁 Project Structure

```text
Ecommerce_Sales_Analysis/
│
├── project.sql
├── order_list.csv
├── order_details.csv
├── sales_target.csv
├── README.md
```

##▶️ How to Run the Project
1. Open MySQL Workbench
2. Run the SQL script:
3. project.sql
4. Import CSV datasets using:
5. Table Data Import Wizard
6. Execute analytical SQL queries

##📈 Key Learning Outcomes
Through this project, I gained hands-on experience in:
1. Relational database creation
2. SQL-based business analytics
3. Data cleaning and preprocessing
4. Handling foreign key constraints
5. Writing optimized analytical queries
6. Converting raw transactional data into actionable insights

##⭐ Conclusion
This project showcases practical SQL and database management skills through real-world E-commerce sales analysis and business intelligence reporting. It reflects strong understanding of SQL fundamentals, data analytics workflows, and relational database concepts relevant to Data Analyst and Business Analyst roles.
