-- TASK 25: Multi-Table Sales Analysis
-- Dataset: Microsoft Northwind
-- SQL dialect: SQL Server / T-SQL
-- Purpose: combine Orders, Order Details, Products, Categories and Customers
-- while avoiding double counting caused by one-to-many joins.

USE Northwind;
GO

/* =========================================================
   1. DATA VALIDATION / RELATIONSHIP CHECKS
   ========================================================= */

-- Orders should have matching customers
SELECT COUNT(*) AS OrdersWithoutCustomer
FROM Orders o
LEFT JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE c.CustomerID IS NULL;

-- Order Details should have matching orders
SELECT COUNT(*) AS DetailsWithoutOrder
FROM [Order Details] od
LEFT JOIN Orders o ON od.OrderID = o.OrderID
WHERE o.OrderID IS NULL;

-- Order Details should have matching products
SELECT COUNT(*) AS DetailsWithoutProduct
FROM [Order Details] od
LEFT JOIN Products p ON od.ProductID = p.ProductID
WHERE p.ProductID IS NULL;


/* =========================================================
   2. BASE MULTI-TABLE SALES VIEW
   Revenue is calculated at ORDER DETAIL level.
   Freight is intentionally NOT included here because one
   order can have multiple detail rows and would be duplicated.
   ========================================================= */

IF OBJECT_ID('dbo.vw_MultiTableSales', 'V') IS NOT NULL
    DROP VIEW dbo.vw_MultiTableSales;
GO

CREATE VIEW dbo.vw_MultiTableSales
AS
SELECT
    o.OrderID,
    o.OrderDate,
    o.CustomerID,
    c.CompanyName,
    c.Country,
    c.City,
    o.EmployeeID,
    od.ProductID,
    p.ProductName,
    p.CategoryID,
    cat.CategoryName,
    od.UnitPrice,
    od.Quantity,
    od.Discount,
    CAST(od.UnitPrice * od.Quantity * (1 - od.Discount) AS DECIMAL(18,2)) AS NetSales
FROM Orders o
INNER JOIN Customers c
    ON o.CustomerID = c.CustomerID
INNER JOIN [Order Details] od
    ON o.OrderID = od.OrderID
INNER JOIN Products p
    ON od.ProductID = p.ProductID
INNER JOIN Categories cat
    ON p.CategoryID = cat.CategoryID;
GO


/* =========================================================
   3. OVERALL KPIs
   ========================================================= */

SELECT
    COUNT(DISTINCT OrderID) AS TotalOrders,
    COUNT(DISTINCT CustomerID) AS TotalCustomers,
    COUNT(DISTINCT ProductID) AS ProductsSold,
    SUM(Quantity) AS TotalUnitsSold,
    ROUND(SUM(NetSales), 2) AS TotalNetSales,
    ROUND(SUM(NetSales) / NULLIF(COUNT(DISTINCT OrderID),0), 2) AS AvgOrderValue
FROM dbo.vw_MultiTableSales;


/* =========================================================
   4. SALES BY YEAR
   ========================================================= */

SELECT
    YEAR(OrderDate) AS SalesYear,
    ROUND(SUM(NetSales), 2) AS Sales
FROM dbo.vw_MultiTableSales
GROUP BY YEAR(OrderDate)
ORDER BY SalesYear;


/* =========================================================
   5. MONTHLY SALES TREND
   ========================================================= */

SELECT
    YEAR(OrderDate) AS SalesYear,
    MONTH(OrderDate) AS SalesMonth,
    DATENAME(MONTH, OrderDate) AS MonthName,
    ROUND(SUM(NetSales), 2) AS Sales
FROM dbo.vw_MultiTableSales
GROUP BY YEAR(OrderDate), MONTH(OrderDate), DATENAME(MONTH, OrderDate)
ORDER BY SalesYear, SalesMonth;


/* =========================================================
   6. SALES BY CATEGORY
   ========================================================= */

SELECT
    CategoryName,
    SUM(Quantity) AS UnitsSold,
    ROUND(SUM(NetSales), 2) AS Sales
FROM dbo.vw_MultiTableSales
GROUP BY CategoryName
ORDER BY Sales DESC;


/* =========================================================
   7. TOP 10 PRODUCTS BY REVENUE
   ========================================================= */

SELECT TOP 10
    ProductID,
    ProductName,
    CategoryName,
    SUM(Quantity) AS UnitsSold,
    ROUND(SUM(NetSales), 2) AS Sales
FROM dbo.vw_MultiTableSales
GROUP BY ProductID, ProductName, CategoryName
ORDER BY Sales DESC;


/* =========================================================
   8. TOP 10 PRODUCTS BY QUANTITY
   ========================================================= */

SELECT TOP 10
    ProductID,
    ProductName,
    CategoryName,
    SUM(Quantity) AS UnitsSold,
    ROUND(SUM(NetSales), 2) AS Sales
FROM dbo.vw_MultiTableSales
GROUP BY ProductID, ProductName, CategoryName
ORDER BY UnitsSold DESC;


/* =========================================================
   9. TOP 10 CUSTOMERS
   ========================================================= */

SELECT TOP 10
    CustomerID,
    CompanyName,
    Country,
    COUNT(DISTINCT OrderID) AS Orders,
    ROUND(SUM(NetSales), 2) AS Sales
FROM dbo.vw_MultiTableSales
GROUP BY CustomerID, CompanyName, Country
ORDER BY Sales DESC;


/* =========================================================
   10. SALES BY COUNTRY
   ========================================================= */

SELECT
    Country,
    COUNT(DISTINCT CustomerID) AS Customers,
    COUNT(DISTINCT OrderID) AS Orders,
    ROUND(SUM(NetSales), 2) AS Sales
FROM dbo.vw_MultiTableSales
GROUP BY Country
ORDER BY Sales DESC;


/* =========================================================
   11. SALES BY EMPLOYEE
   ========================================================= */

SELECT
    EmployeeID,
    COUNT(DISTINCT OrderID) AS OrdersHandled,
    ROUND(SUM(NetSales), 2) AS Sales
FROM dbo.vw_MultiTableSales
GROUP BY EmployeeID
ORDER BY Sales DESC;


/* =========================================================
   12. DISCOUNT ANALYSIS
   ========================================================= */

SELECT
    CategoryName,
    ROUND(AVG(Discount) * 100, 2) AS AvgDiscountPercent,
    ROUND(SUM(UnitPrice * Quantity * Discount), 2) AS DiscountValue
FROM dbo.vw_MultiTableSales
GROUP BY CategoryName
ORDER BY DiscountValue DESC;


/* =========================================================
   13. SHIPPING ANALYSIS
   IMPORTANT: Freight is calculated once per order.
   ========================================================= */

SELECT
    s.CompanyName AS Shipper,
    COUNT(*) AS OrdersShipped,
    ROUND(AVG(DATEDIFF(DAY, o.OrderDate, o.ShippedDate)), 2) AS AvgShippingDays,
    ROUND(SUM(o.Freight), 2) AS TotalFreight
FROM Orders o
INNER JOIN Shippers s
    ON o.ShipVia = s.ShipperID
WHERE o.ShippedDate IS NOT NULL
GROUP BY s.CompanyName
ORDER BY OrdersShipped DESC;


/* =========================================================
   14. ON-TIME DELIVERY
   ========================================================= */

SELECT
    COUNT(*) AS ShippedOrders,
    SUM(CASE WHEN ShippedDate <= RequiredDate THEN 1 ELSE 0 END) AS OnTimeOrders,
    ROUND(
        100.0 * SUM(CASE WHEN ShippedDate <= RequiredDate THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*),0), 2
    ) AS OnTimeRatePercent
FROM Orders
WHERE ShippedDate IS NOT NULL;


/* =========================================================
   15. ORDER-LEVEL SUMMARY
   Use this when combining order-level fields such as Freight
   with revenue. It prevents freight duplication.
   ========================================================= */

WITH OrderRevenue AS (
    SELECT
        OrderID,
        SUM(NetSales) AS OrderSales
    FROM dbo.vw_MultiTableSales
    GROUP BY OrderID
)
SELECT
    o.OrderID,
    o.OrderDate,
    c.CompanyName,
    o.Freight,
    ROUND(orv.OrderSales, 2) AS OrderSales,
    ROUND(orv.OrderSales + o.Freight, 2) AS SalesPlusFreight
FROM Orders o
INNER JOIN Customers c
    ON o.CustomerID = c.CustomerID
INNER JOIN OrderRevenue orv
    ON o.OrderID = orv.OrderID
ORDER BY o.OrderDate;


/* =========================================================
   16. DOUBLE-COUNTING DEMONSTRATION
   NEVER SUM o.Freight after directly joining Order Details.
   ========================================================= */

-- WRONG APPROACH:
-- SELECT SUM(o.Freight)
-- FROM Orders o
-- JOIN [Order Details] od ON o.OrderID = od.OrderID;

-- CORRECT:
SELECT ROUND(SUM(Freight), 2) AS CorrectTotalFreight
FROM Orders;


/* =========================================================
   17. FIVE BUSINESS QUESTIONS / INSIGHTS QUERIES
   ========================================================= */

-- Q1: Which categories generate the most revenue?
SELECT CategoryName, ROUND(SUM(NetSales),2) AS Sales
FROM dbo.vw_MultiTableSales
GROUP BY CategoryName
ORDER BY Sales DESC;

-- Q2: Which products are the biggest revenue drivers?
SELECT TOP 5 ProductName, CategoryName, ROUND(SUM(NetSales),2) AS Sales
FROM dbo.vw_MultiTableSales
GROUP BY ProductName, CategoryName
ORDER BY Sales DESC;

-- Q3: Which customers contribute the most?
SELECT TOP 5 CompanyName, Country, ROUND(SUM(NetSales),2) AS Sales
FROM dbo.vw_MultiTableSales
GROUP BY CompanyName, Country
ORDER BY Sales DESC;

-- Q4: Which countries generate the most sales?
SELECT TOP 10 Country, ROUND(SUM(NetSales),2) AS Sales
FROM dbo.vw_MultiTableSales
GROUP BY Country
ORDER BY Sales DESC;

-- Q5: How does sales change over time?
SELECT
    YEAR(OrderDate) AS SalesYear,
    MONTH(OrderDate) AS SalesMonth,
    ROUND(SUM(NetSales),2) AS Sales
FROM dbo.vw_MultiTableSales
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY SalesYear, SalesMonth;
GO
