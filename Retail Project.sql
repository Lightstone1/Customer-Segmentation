-- CREATE A NEW TABLE TO ACCOMODATE the clean DATA

SELECT TOP 0 *
INTO Retail_New
FROM Retail;

sELECT * FROM Retail;

--STEP:1 INSERT THE OLD DATA INTO NEW TABLE FOR CLEANING --

INSERT Retail_New
SELECT * FROM Retail;

sELECT * FROM Retail_New;

---STEP 2: CHECKING FOR DUPLICATES--

SELECT
    *,
    ROW_NUMBER() OVER (
        PARTITION BY InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country 
        ORDER BY (select null)  -- This is often used when the ordering does not matter
    ) as Row_Num
FROM
    Retail_New R;

-- Add CTE-- 

With duplicates_cte as (
SELECT
    *,
    ROW_NUMBER() OVER (
        PARTITION BY InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country 
        ORDER BY (select null)  -- This is often used when the ordering does not matter
    ) as Row_Num
FROM
    Retail_New R
)
Select * FROM duplicates_cte Where Row_Num > 1


/*Confirming the duplicate
select
*
FROM
 Retail_New R
 where
 InvoiceNo = 536409
 And StockCode = '21866'
 And CustomerID = '17908'*/



 -- DELETING DUPLICATES (5268 Rows deleted)--
With duplicates_cte as (
SELECT
    *,
    ROW_NUMBER() OVER (
        PARTITION BY InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country 
        ORDER BY (select null)  -- This is often used when the ordering does not matter
    ) as Row_Num
FROM
    Retail_New R
)
DELETE
FROM
duplicates_cte
WHERE Row_Num >1



-- STEP 3: STANDARDIZING DATA (data type with text)--
Select * from Retail_New;

select distinct StockCode from Retail_New order by 1;

Update Retail_New
Set 
InvoiceNo = TRIM(InvoiceNo),
 StockCode = TRIM(StockCode),
 Description = TRIM(Description),
 Country = TRIM(Country)
;

---Splitting the InvoiceDate to Date and Time columns--


-- Add new columns
ALTER TABLE Retail_New
ADD DatePart DATE,
    TimePart TIME;

-- Update the new columns with the extracted values
UPDATE Retail_New
SET 
    InvoiceDate = CAST(InvoiceDate AS DATE),
    InvoiceTime = CAST(InvoiceDate AS TIME);

--Deleting the old invoicedate--

ALTER TABLE Retail_New
DROP COLUMN InvoiceDate;


-- STEP: 4 Cleaning for Nulls or empty
Select * from Retail_New;


Select *  /* 135,037 rows are null , so i will be dropping them*/
from Retail_New
where CustomerID = ' '
OR CustomerID IS NULL

DELETE 
from Retail_New
where CustomerID = ' '
OR CustomerID IS NULL


Select * /*WE have 40 rows with 0 as  unit price, so i will be deleting them*/
from Retail_New
where UnitPrice = ' '
OR UnitPrice IS NULL

Delete
from Retail_New
where UnitPrice = ' '
OR UnitPrice IS NULL


--CHECKING OTHER COLUMNS FOR NULLs or empty columns--


Select *
from Retail_New
where InvoiceNo = ' '
OR InvoiceNo IS NULL


Select *
from Retail_New
where StockCode = ' '
OR StockCode IS NULL


Select *
from Retail_New
where Description = ' '
OR Description IS NULL


Select *
from Retail_New
where Quantity = ' '
OR Quantity IS NULL



Select *
from Retail_New
where Country = ' '
OR Country IS NULL

Select *
from Retail_New
where InvoiceDate = ' '
OR InvoiceDate IS NULL


--Converting some rows with negative value to positive--
UPDATE Retail_New
SET Quantity = ABS(Quantity);

Select 
*
from Retail_New 
where 
Quantity <0

---Rounding the Unit price to 2 decimal--
UPDATE Retail_New
SET UnitPrice= ROUND(UnitPrice, 2);


--QUESTION ONE (What is the distribution of order values across all customers in the dataset?) --

WITH CTE AS (
    SELECT 
        CustomerID,
        SUM(Quantity * UnitPrice) AS TotalOrderValue
    FROM 
        Retail_New
    GROUP BY 
        CustomerID
)
SELECT *,
    CASE 
        WHEN TotalOrderValue < 500 THEN 'Very Low'
        WHEN TotalOrderValue BETWEEN 500 AND 999 THEN 'Low'
        WHEN TotalOrderValue BETWEEN 1000 AND 4999 THEN 'Medium'
        WHEN TotalOrderValue BETWEEN 5000 AND 9999 THEN 'High'
        ELSE 'Very High'
    END AS OrderValueCategory
FROM CTE
ORDER BY CustomerID;


--OPTION 2--

WITH CTE AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY (SELECT NULL)) AS RowNumber,
        SUM(Quantity * UnitPrice) OVER (PARTITION BY CustomerID) AS TotalOrderValue
    FROM 
        Retail_New
)
SELECT *,
CASE 
        WHEN TotalOrderValue < 500 THEN 'Very Low'
        WHEN TotalOrderValue BETWEEN 500 AND 999 THEN 'Low'
        WHEN TotalOrderValue BETWEEN 1000 AND 4999 THEN 'Medium'
        WHEN TotalOrderValue BETWEEN 5000 AND 9999 THEN 'High'
        ELSE 'Very High'
    END AS OrderValueCategory
FROM CTE
WHERE RowNumber = 1;





--QUESTION TWO 9How many unique products has each customer purchased?) --

 WITH CTE AS (
    SELECT 
        *,
        SUM(Quantity * UnitPrice) OVER (PARTITION BY CustomerID) AS TotalOrderValue,
        ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY (SELECT NULL)) AS RowNumber
    FROM 
        Retail_New
) 
SELECT 
    CustomerID, 
    COUNT(DISTINCT StockCode) AS UniqueProductsPurchased
FROM
    CTE
GROUP BY 
    CustomerID
ORDER BY CustomerID
	;



-- QUESTION THREE (Which customers have only made a single purchase from the company?) --

WITH CustomerPurchaseCount AS (
    SELECT 
        CustomerID,
        COUNT(*) AS PurchaseCount
    FROM 
        Retail_New
    GROUP BY 
        CustomerID
)
SELECT 
    *
FROM 
    Retail_New
JOIN 
    CustomerPurchaseCount ON Retail_New.CustomerID = CustomerPurchaseCount.CustomerID
WHERE 
    CustomerPurchaseCount.PurchaseCount = 1;



	--OPTION TWO--
WITH CustomerPurchaseCount AS (
    SELECT 
        CustomerID,
        COUNT(*) AS PurchaseCount
    FROM 
        Retail_New
    GROUP BY 
        CustomerID
)
SELECT 
    *
	from
	CustomerPurchaseCount
	where PurchaseCount =1


/*QUESTION 4 (Which products are most commonly purchased together by customers in the
dataset?)*/

-- Step 1: Create a CTE to get product pairs within the same transaction
WITH ProductPairs AS (
    SELECT 
        a.CustomerID,
        a.InvoiceNo,
        a.StockCode AS Product1,
        b.StockCode AS Product2
    FROM 
        Retail_New a
    JOIN 
        Retail_New b
    ON 
        a.InvoiceNo = b.InvoiceNo
        AND a.StockCode < b.StockCode -- Ensure each pair is unique and avoid self-joins
)

-- Step 2: Count the frequency of each product pair
SELECT 
    Product1,
    Product2,
    COUNT(*) AS Frequency
FROM 
    ProductPairs
GROUP BY 
    Product1,
    Product2
ORDER BY 
    Frequency DESC;
