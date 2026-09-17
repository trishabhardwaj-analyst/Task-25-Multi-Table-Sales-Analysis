Task 25 – Multi-Table Sales Analysis

Objective

Combine Northwind's Orders, Customers, Products, Categories and Order Details tables to perform end-to-end relational sales analysis using SQL and Power BI.

Dataset

Microsoft Northwind sample database.

Core tables:

Customers

Orders

Order Details

Products

Categories

Employees

Shippers

Microsoft documents Northwind as a relational sample database and provides the SQL script for creating/loading it.

Tools

SQL Server / SSMS

Power BI Desktop

SQL

DAX

Files

task25_multitable_sales_analysis.sql – complete SQL analysis script

task25_powerbi_guide.md – Power BI model, measures and visuals

task25_5_insights.txt – five business insights

task25_report.pdf – submission-ready report

task25_dashboard_preview.png – dashboard layout preview

Key SQL concepts demonstrated

INNER JOIN across multiple tables

Aggregation with GROUP BY

COUNT(DISTINCT ...) for avoiding duplicate order counts

Revenue calculation at order-detail level

CTE for order-level aggregation

Validation of foreign-key relationships

Shipping and delivery analysis

Avoiding freight double-counting

Important double-counting rule

Orders is one-to-many with Order Details. If an order contains five products, joining Orders to Order Details creates five rows for that order. Therefore, an order-level value such as Freight must not be summed directly after that join.

For revenue, calculate:
UnitPrice × Quantity × (1 - Discount)

For freight, aggregate from the Orders table separately or first aggregate sales to one row per OrderID.

Power BI model

Recommended relationships:

Customers[CustomerID] → Orders[CustomerID]

Orders[OrderID] → Order Details[OrderID]

Products[ProductID] → Order Details[ProductID]

Categories[CategoryID] → Products[CategoryID]

Employees[EmployeeID] → Orders[EmployeeID]

Shippers[ShipperID] → Orders[ShipVia]

Use single-direction filtering from dimension tables to fact tables.

Dashboard

Suggested pages/sections:

Executive Sales Overview

Product & Category Analysis

Customer & Geography Analysis

Shipping & Employee Analysis

Submission checklist:-

1.SQL script executed successfully

2.Relationships validated

3.Power BI relationships created

4.KPI cards added

5.Sales trend added

6.Category/product/customer visuals added

7.Five insights written

8.Dashboard screenshot exported

9.README uploaded to GitHub
