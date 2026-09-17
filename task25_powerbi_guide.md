# Task 25 – Power BI Guide

## 1. Import data
In Power BI Desktop:
1. Get Data → SQL Server.
2. Enter your SQL Server instance.
3. Select the Northwind database.
4. Load: Customers, Orders, Order Details, Products, Categories, Employees and Shippers.

## 2. Create relationships
Create these one-to-many relationships:

Customers[CustomerID] 1 → * Orders[CustomerID]
Orders[OrderID] 1 → * Order Details[OrderID]
Products[ProductID] 1 → * Order Details[ProductID]
Categories[CategoryID] 1 → * Products[CategoryID]
Employees[EmployeeID] 1 → * Orders[EmployeeID]
Shippers[ShipperID] 1 → * Orders[ShipVia]

## 3. Create measures

```DAX
Total Sales =
SUMX(
    'Order Details',
    'Order Details'[UnitPrice] *
    'Order Details'[Quantity] *
    (1 - 'Order Details'[Discount])
)

Total Orders =
DISTINCTCOUNT(Orders[OrderID])

Total Customers =
DISTINCTCOUNT(Customers[CustomerID])

Total Units =
SUM('Order Details'[Quantity])

Average Order Value =
DIVIDE([Total Sales], [Total Orders])

Total Freight =
SUM(Orders[Freight])

Average Shipping Days =
AVERAGEX(
    FILTER(
        Orders,
        NOT ISBLANK(Orders[ShippedDate])
    ),
    DATEDIFF(
        Orders[OrderDate],
        Orders[ShippedDate],
        DAY
    )
)

On-Time Orders =
CALCULATE(
    DISTINCTCOUNT(Orders[OrderID]),
    FILTER(
        Orders,
        NOT ISBLANK(Orders[ShippedDate]) &&
        Orders[ShippedDate] <= Orders[RequiredDate]
    )
)

On-Time Rate =
DIVIDE([On-Time Orders], [Total Orders])
```

## 4. Dashboard layout

### KPI cards
- Total Sales
- Total Orders
- Total Customers
- Total Units
- Average Order Value

### Visual 1 – Sales Trend
Line chart:
- X-axis: Orders[OrderDate]
- Y-axis: [Total Sales]

### Visual 2 – Sales by Category
Clustered bar:
- Axis: Categories[CategoryName]
- Values: [Total Sales]

### Visual 3 – Top Products
Bar chart:
- Axis: Products[ProductName]
- Values: [Total Sales]
- Visual filter: Top 10 by [Total Sales]

### Visual 4 – Country Performance
Map or bar chart:
- Location: Customers[Country]
- Values: [Total Sales]

### Visual 5 – Top Customers
Bar chart:
- Axis: Customers[CompanyName]
- Values: [Total Sales]
- Top 10 filter

### Visual 6 – Shipping
Table:
- Shipper
- Orders shipped
- Total freight
- Average shipping days

## 5. Slicers
Add:
- Year
- Country
- Category
- Customer
- Employee

## 6. Double-counting warning
Do not create a measure like:
`SUM(Orders[Freight])` after building a flattened Orders × Order Details table. The same order can appear multiple times.

Keep Orders as an order-level table and Order Details as the line-item fact table.
