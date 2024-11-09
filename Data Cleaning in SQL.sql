-- Step 1: Create Staging Table Structure
-- This will create the `stock_data_staging` table with the same structure as `stock_data`, but no rows.

SELECT TOP 0 *
INTO stock_data_staging
FROM stock_data;

-- Step 2: Import Data into the Staging Table
-- Copy all data from `stock_data` to `stock_data_staging`

INSERT INTO stock_data_staging
SELECT *
FROM stock_data;

-- Step 3: Data Cleaning in the Staging Table

-- Step 3a: Handle Missing Values (Delete Rows with NULLs in Required Columns)
-- Deletes rows where critical columns (`open`, `high`, `low`, `close`, `volume`, `name`) are NULL.

DELETE FROM stock_data_staging
WHERE [open] IS NULL 
   OR high IS NULL 
   OR low IS NULL 
   OR [close] IS NULL 
   OR volume IS NULL 
   OR name IS NULL;

-- Step 3b: Ensure Date Format Consistency
-- Convert the `date` column to DATE type if it's not already in that format.

ALTER TABLE stock_data_staging
ALTER COLUMN [date] DATE;

-- Step 3c: Check and Remove Duplicates
-- Use ROW_NUMBER to identify duplicate rows based on `date` and `name`, and keep only the first occurrence.

WITH duplicate_cte AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY [date], [name] ORDER BY [date]) AS row_num
    FROM stock_data_staging
)
DELETE FROM duplicate_cte
WHERE row_num > 1;

-- Step 3d: Standardize Text Data
-- Remove any leading/trailing whitespace from `name` column values.

UPDATE stock_data_staging
SET name = TRIM(name);

-- Step 3e: Remove Rows with Blank or Non-Numeric Values in `open` Column
-- Check if `open` column contains any blank or non-numeric values and delete these rows.

DELETE FROM stock_data_staging
WHERE [open] = ' ';		-- Removes blanks in `open`

-- Verify Results After Cleaning

SELECT *
FROM stock_data_staging;
