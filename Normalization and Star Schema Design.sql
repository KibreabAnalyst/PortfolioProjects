
-- Title: Normalization and Star Schema Design for Bike Store Sales Data
-- Date: [August 21, 2024]
-- This script normalizes the existing sales data by creating
--  dimension tables and a fact table for the bike store sales.

-- ================================================
-- Create Date Dimension Table
-- ================================================
-- Auto-incrementing DateID

CREATE TABLE DimDate (
    DateID INT PRIMARY KEY IDENTITY(1,1),
	Date Date,
    Day INT,
    Month INT,
    Year INT,
    Quarter INT,
    Weekday VARCHAR(10)
);
-- Populate DimDate
-- Populate the Date Dimension Table with distinct date values from the Sales table
-- This ensures that each unique date in the sales data is represented.

INSERT INTO DimDate (Date, Day, Month, Year, Quarter, Weekday)
SELECT DISTINCT
	Date AS Date,													
    DAY(Date) AS Day,
    MONTH(Date) AS Month,
    YEAR(Date) AS Year,
    DATEPART(QUARTER, Date) AS Quarter,
    DATENAME(WEEKDAY, Date) AS Weekday
FROM
    Sales;

-- ================================================
-- Create Customer Dimension Table
-- ================================================
-- Auto-incrementing CustomerID

CREATE TABLE DimCustomer (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    Customer_Age INT,
    Age_Group VARCHAR(50),
    Customer_Gender VARCHAR(10)
);
-- Populate DimCustomer
-- Populate the Customer Dimension Table with distinct customer details from the Sales table.

INSERT INTO DimCustomer (Customer_Age, Age_Group, Customer_Gender)
SELECT DISTINCT
    Customer_Age,
    Age_Group,
    Customer_Gender
FROM
    Sales;

-- ================================================
-- Create Location Dimension Table
-- ================================================
-- Auto-incrementing LocationID

CREATE TABLE DimLocation (
    LocationID INT PRIMARY KEY IDENTITY(1,1),
    Country VARCHAR(50),
    State VARCHAR(50)
);
-- Populate DimLocation
-- Populate the Location Dimension Table with distinct location details from the Sales table.

INSERT INTO DimLocation (Country, State)
SELECT DISTINCT
    Country,
    State
FROM
    Sales;

-- ================================================
-- Create Product Dimension Table
-- ================================================
-- Auto-incrementing ProductID

CREATE TABLE DimProduct (
    ProductID INT PRIMARY KEY IDENTITY(1,1),	
    Product_Category VARCHAR(50),
    Sub_Category VARCHAR(50),
    Product_Name VARCHAR(100)
);
-- Populate DimProduct
-- Populate the Product Dimension Table with distinct product details from the Sales table.

INSERT INTO DimProduct (Product_Category, Sub_Category, Product_Name)
SELECT DISTINCT
    Product_Category,
    Sub_Category,
    Product
FROM
    Sales;

-- ================================================
-- Create Fact Table
-- ================================================
-- Auto-incrementing FactID

CREATE TABLE FactSales (
    FactID INT PRIMARY KEY IDENTITY(1,1),
    DateID INT,
    CustomerID INT,
    ProductID INT,
    LocationID INT,
    Order_Quantity INT,
    Unit_Cost DECIMAL(10, 2),
    Unit_Price DECIMAL(10, 2),
    Profit DECIMAL(10, 2),
    Cost DECIMAL(10, 2),
    Revenue DECIMAL(10, 2),
    FOREIGN KEY (DateID) REFERENCES DimDate(DateID),
    FOREIGN KEY (CustomerID) REFERENCES DimCustomer(CustomerID),
    FOREIGN KEY (ProductID) REFERENCES DimProduct(ProductID),
    FOREIGN KEY (LocationID) REFERENCES DimLocation(LocationID)
);
-- Populate FactSales
-- Populate the FactSales Table by joining the Sales table with the dimension tables.
-- This step links each sale to the appropriate Date, Customer, Product, and Location.

INSERT INTO FactSales (DateID, CustomerID, ProductID, LocationID, Order_Quantity, Unit_Cost, Unit_Price, Profit, Cost, Revenue)
SELECT 
    dd.DateID,
    dc.CustomerID,
    dp.ProductID,
    dl.LocationID,
    et.Order_Quantity,
    et.Unit_Cost,
    et.Unit_Price,
    et.Profit,
    et.Cost,
    et.Revenue
FROM
    Sales et
JOIN
    DimDate dd ON 
        DAY(et.Date) = dd.Day AND 
        MONTH(et.Date) = dd.Month AND 
        YEAR(et.Date) = dd.Year
JOIN
    DimCustomer dc ON 
        et.Customer_Age = dc.Customer_Age AND 
        et.Age_Group = dc.Age_Group AND 
        et.Customer_Gender = dc.Customer_Gender
JOIN
    DimProduct dp ON 
        et.Product_Category = dp.Product_Category AND 
        et.Sub_Category = dp.Sub_Category AND 
        et.Product = dp.Product_Name
JOIN
    DimLocation dl ON 
        et.Country = dl.Country AND 
        et.State = dl.State;