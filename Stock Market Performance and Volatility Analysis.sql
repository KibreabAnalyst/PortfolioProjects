-- Analyze stock data trends, volatility, and performance metrics on daily, monthly, and yearly bases.

-- 1. Monthly Trend in Closing Prices
-- Calculate the average monthly closing price for each stock to observe long-term trends over time.
SELECT
	name,
	YEAR(date) AS year,
	MONTH(date) AS month,
	AVG([close]) AS avg_monthly_close
FROM stock_data_staging
GROUP BY name, YEAR(date), MONTH(date)
ORDER BY name, year, month;

-- 2. Yearly Trend in Closing Prices
-- Calculate the average yearly closing price for each stock for an annual trend overview.
SELECT
	name,
	YEAR(date) AS year,
	AVG([close]) AS avg_yearly_close
FROM stock_data_staging
GROUP BY name, YEAR(date)
ORDER BY name, year;

-- 3. Daily Closing Prices (for detailed trend analysis)
-- Retrieve daily closing prices for each stock to allow for detailed day-by-day trend analysis.
SELECT
	name,
	date,
	[close]
FROM stock_data_staging
ORDER BY name, date;

-- 4. Seasonal Patterns in Stock Prices
-- Calculate the average closing price for each month to identify seasonal price patterns.
SELECT
	name,
	MONTH(date) AS month,
	AVG([close]) AS avg_monthly_close
FROM stock_data_staging
GROUP BY name, MONTH(date)
ORDER BY name, month;

-- 5. Daily Volatility
-- Calculate daily volatility as the difference between the high and low prices for each day.
SELECT
	name,
	date,
	(high - low) AS daily_volatility
FROM stock_data_staging
ORDER BY name, daily_volatility DESC;

-- 6. Monthly Volatility
-- Calculate average monthly volatility for each stock, based on daily high-low differences within each month.
SELECT
	name,
	YEAR(date) AS year,
	MONTH(date) AS month,
	AVG(high - low) AS avg_monthly_volatility
FROM stock_data_staging
GROUP BY name, YEAR(date), MONTH(date)
ORDER BY  avg_monthly_volatility DESC;

-- 7. Performance Over a Specific Period
-- Measure stock performance over each year based on the percentage change from the first to the last closing price.
-- Step 1: Capture yearly opening and closing prices using window functions.
WITH yearly_performance AS (
SELECT
	name,
	YEAR(date) AS year,
	FIRST_VALUE([close]) OVER(PARTITION BY name, YEAR(date) ORDER BY date ASC) AS first_close,
	LAST_VALUE([close]) OVER(PARTITION BY name, YEAR(date) ORDER BY date ASC RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_close
FROM stock_data_staging
),
-- Step 2: Calculate the percentage change in closing price for each stock in each year
performance_change AS (
SELECT 
	name,
	year,
	first_close,
	last_close,
	((last_close - first_close) / first_close) * 100 AS pct_change
FROM yearly_performance
)
-- Step 3: Rank stocks by their yearly performance to identify best and worst performers.
SELECT
	name,
	year,
	pct_change,
	RANK() OVER(PARTITION BY year ORDER BY pct_change DESC) AS performance_rank
FROM performance_change
ORDER BY year, performance_rank;

-- 8. Daily Percentage Change in Price
-- Calculate the daily percentage change in closing price to analyze daily stock fluctuations.
-- Step 1: Retrieve the closing price from the previous day for each stock.
WITH daily_price_change AS (
SELECT
	name,
	date,
	[close] AS current_close,
	LAG([close]) OVER(PARTITION BY name ORDER BY date) AS previous_close
FROM stock_data_staging
),
-- Step 2: Calculate the daily percentage change in price.
daily_percentage_change AS (
SELECT
	name,
	date,
	CASE
			WHEN previous_close IS NOT NULL THEN ((current_close - previous_close) / previous_close) * 100
			ELSE 0
	END AS daily_pct_change
FROM daily_price_change
)
-- Final Query: Calculate the average daily percentage change for each stock to understand typical daily fluctuations.
SELECT
	name,
	AVG(ABS(daily_pct_change)) AS avg_daily_pct_change
FROM daily_percentage_change
GROUP BY name
ORDER BY avg_daily_pct_change DESC;

-- 9. Monthly Percentage Change in Price
-- Calculate the monthly percentage change in closing prices to identify typical monthly fluctuations.
-- Step 1: Retrieve the last closing price for each stock within each month.
WITH monthly_close_cte AS (
SELECT
	name,
	YEAR(date) AS year,
	MONTH(date) AS month,
	[close] AS monthly_close,
	LAG([close]) OVER(PARTITION BY name ORDER BY YEAR(date), MONTH(date)) AS previous_month_close
FROM (
		SELECT
			name,
			date,
			[close],
			ROW_NUMBER() OVER(PARTITION BY name, YEAR(date), MONTH(date) ORDER BY date DESC) AS rn
		FROM stock_data_staging
) AS last_day_close
WHERE rn = 1
),
-- Step 2: Calculate the monthly percentage change for each stock.
monthly_percentage_change AS (
SELECT
	name,
	year,
	month,
	CASE
			WHEN previous_month_close IS NOT NULL THEN ((monthly_close - previous_month_close) / previous_month_close) * 100 
			ELSE 0
	END AS monthly_pct_change
FROM monthly_close_cte
)
-- Final Query: Calculate the average monthly percentage change for each stock.
SELECT
	name,
	AVG(ABS(monthly_pct_change)) AS avg_monthly_pct_change
FROM monthly_percentage_change
GROUP BY name
ORDER BY avg_monthly_pct_change DESC;