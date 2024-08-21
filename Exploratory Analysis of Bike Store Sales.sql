-- Total Sales by Month:
-- Aggregating total sales by month and year to identify monthly sales trends

select 
		DATEPART(year, d.Date) as Year,		-- Extracting the year part of the date
		DATEPART(month, d.Date) as Month,		-- Extracting the month part of the date
		SUM(f.Revenue) as TotalSales		-- Summing up the revenue to calculate total sales for each month
from FactSales f
join DimDate d on f.DateID = d.DateID		-- Joining the FactSales table with the DimDate table using DateID
group by DATEPART(year, d.Date),
				DATEPART(month, d.Date)			-- Grouping by year and month to aggregate the data
order by Year, Month;		-- Sorting the results by year and month

--------------------------------------------------------------------------------

-- Total Sales by Quarter:
-- Aggregating total sales by quarter and year to understand quarterly performance

select 
		DATEPART(YEAR, d.Date) as Year,
		DATEPART(QUARTER, d.Date) as Quarter,
		SUM(f.Revenue) as TotalSales
from FactSales f
join DimDate d on f.DateID = d.DateID
group by DATEPART(YEAR, d.Date),
				DATEPART(QUARTER, d.Date)
order by Year, Quarter;

--------------------------------------------------------------------------------

-- Sales and Units Sold by Product Category:
-- Analyzing sales and units sold by product category to identify top-performing categories

select 
		p.Product_Category as Category,
		SUM(f.Revenue) as TotalSales,
		SUM(f.Order_Quantity) as UnitsSold
from FactSales f
join DimProduct p on f.ProductID = p.ProductID
group by p.Product_Category
order by TotalSales desc;

--------------------------------------------------------------------------------

-- Sales and Units Sold by Product Name:
-- Drilling down to analyze sales and units sold by individual product names

select 
		p.Product_Name as BikeModel,
		SUM(f.Revenue) as TotalSales,
		SUM(f.Order_Quantity) as UnitsSold
from FactSales f
join DimProduct p on f.ProductID = p.ProductID
group by p.Product_Name
order by TotalSales desc;

--------------------------------------------------------------------------------

-- Regional Sales Performance:
-- Evaluating sales performance across different regions to identify geographical trends

select 
		l.Country as Region,
		SUM(f.Revenue) as TotalRevenue,
		SUM(f.Order_Quantity) as TotalUnitsSold,
		SUM(f.Profit) as TotalProfit,
		AVG(f.Revenue) as AverageRevenuePerSale,
		AVG(f.Profit) as AverageProfitPerSale
from FactSales f
join DimLocation l on f.LocationID = l.LocationID
group by l.Country
order by TotalRevenue desc;

--------------------------------------------------------------------------------

-- Average Sales for Each Season:
-- Analyzing average sales across different seasons to identify seasonal trends


with SeasonalSales as (						-- Using a Common Table Expression (CTE) to simplify seasonal analysis
select 
		case
				when d.Month in (12, 1, 2) then 'Winter'		-- Grouping months into Winter
				when d.Month in (3, 4, 5) then 'Spring'		-- Grouping months into Spring
				when d.Month in (6, 7, 8) then 'Summer'		-- Grouping months into Summer
				when d.Month in (9, 10, 11) then 'Autumn'		-- Grouping months into Autumn
		end as Season,				-- Creating a column to represent the season
		SUM(f.Revenue) as TotalSales			-- Summing up the revenue to calculate total sales for each season
from FactSales f
join DimDate d on f.DateID = d.DateID
group by 
		case 
                when d.Month in (12, 1, 2) then 'Winter'
				when d.Month in (3, 4, 5) then 'Spring'
				when d.Month in (6, 7, 8) then 'Summer'
				when d.Month in (9, 10, 11) then 'Autumn'
		end
)
select 
		Season,
		AVG(TotalSales) as AverageSales				-- Calculating the average sales for each season
from SeasonalSales
group by Season
order by
		case					-- Ordering the results to follow the natural order of seasons
				when Season = 'Winter' then 1
				when Season = 'Spring' then 2
				when Season = 'Summer' then 3
				when Season = 'Autumn' then 4
		end;

--------------------------------------------------------------------------------

-- Month-over-Month Growth Rate:
-- Calculating the month-over-month growth rate to monitor short-term performance

with MonthlySales as (
	select 
			DATEPART(year, d.Date) as Year,
			DATEPART(month, d.Date) as Month,
			SUM(f.Revenue) as TotalSales
	from FactSales f
	join DimDate d on f.DateID = d.DateID 
	group by DATEPART(year, d.Date),
					DATEPART(month, d.Date)
)
select
    [Current].Year,
    [Current].Month,
    [Current].TotalSales as CurrentMonthSales,
    [Previous].TotalSales as PreviousMonthSales,
    case
        when [Previous].TotalSales is null then NULL
        else ([Current].TotalSales - [Previous].TotalSales) / [Previous].TotalSales * 100
    end as GrowthRatePercentage
from MonthlySales as [Current]
left join MonthlySales as [Previous] on [Current].Year = [Previous].Year
		and ([Current].Month = [Previous].Month + 1
        or ([Current].Month = 1 and [Previous].Month = 12 and [Current].Year = [Previous].Year + 1))
order by [Current].Year, [Current].Month;

--------------------------------------------------------------------------------

-- Quarter-over-Quarter Growth Rate:
-- Calculating the quarter-over-quarter growth rate to monitor medium-term performance


with QuarterlySales as  (
select 
		DATEPART(YEAR, d.Date) as Year,
		DATEPART(QUARTER, d.Date) as Quarter,
		SUM(f.Revenue) as TotalSales
from FactSales f
join DimDate d on f.DateID = d.DateID
group by DATEPART(YEAR, d.Date),
				DATEPART(QUARTER, d.Date)
)
select
    [Current].Year,
    [Current].Quarter,
    [Current].TotalSales as CurrentQuarterSales,
    [Previous].TotalSales as PreviousQuarterSales,
    case
        when [Previous].TotalSales is null then NULL
        else ([Current].TotalSales - [Previous].TotalSales) / [Previous].TotalSales * 100
    end as GrowthRatePercentage
from QuarterlySales as [Current]
left join QuarterlySales as [Previous] on [Current].Year = [Previous].Year
			and ([Current].Quarter = [Previous].Quarter + 1 
			or ([Current].Quarter = 1 and [Previous].Quarter = 4 and [Current].Year = [Previous].Year + 1))
order by [Current].Year, [Current].Quarter;

--------------------------------------------------------------------------------

--  Customer Segmentation:
-- Segmenting customers based on their purchase behavior to categorize them into value segments

-- Step 1: Calculate metrics for each customer

with CustomerMetrics  as (
select 
		c.CustomerID,
		COUNT(f.FactID) as PurchaseFrequency,
		SUM(f.Revenue) as TotalRevenue,
        AVG(f.Revenue) as AverageSpend,
        SUM(f.Profit) as TotalProfit
from FactSales f
join DimCustomer c on f.CustomerID = c.CustomerID
group by c.CustomerID
)
-- Step 2: Segment customers based on calculated metrics
select 
		CustomerID,
		PurchaseFrequency,
		TotalRevenue,
		AverageSpend,
		TotalProfit,
		case
				when PurchaseFrequency > 10 and AverageSpend > 500 then 'High-Value Customer'
				when PurchaseFrequency > 5 and AverageSpend > 200 then 'Medium-Value Customer'
				else 'Low-Value Customer'
		end as CustomerSegment
from CustomerMetrics
order by TotalRevenue desc;


