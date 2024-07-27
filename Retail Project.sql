-- CREATE A NEW TABLE TO ACCOMODATE OUR NEW DATA

SELECT TOP 0 *
INTO Retail_New
FROM Retail;

sELECT * FROM Retail;

--INSERT THE OLD DATA INTO NEW TABLE FOR CLEANING --

INSERT Retail_New
SELECT * FROM Retail;

sELECT * FROM Retail_New;

---CHECKING FOR DUPLICATES--

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



-- STANDARDIZING DATA (data type with text)--
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


-- Cleaning for Nulls or empty
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
