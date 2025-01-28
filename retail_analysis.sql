CREATE DATABASE RETAIL_ANALYSIS;
USE RETAIL_ANALYSIS;

SELECT * FROM CUSTOMER;
SELECT * FROM TRANSACTIONS;
SELECT * FROM PROJEC_CAT_INFO;

-- 1. What is the total number of rows in each of the 3 tables in the database?

SELECT COUNT(*) FROM CUSTOMER;
SELECT COUNT(*) FROM PROJEC_CAT_INFO;
SELECT COUNT(*) FROM TRANSACTIONS;

--2. What is the total number of transactions that have a return?

SELECT
COUNT(TOTAL_AMT) AS RETURN_AMT
FROM 
TRANSACTIONS
WHERE 
TOTAL_AMT LIKE '-%';

/* 3. As you would have noticed, the dates provided across the datasets are 
not in a correct format. As first steps, pls convert the date variables into valid date formats before proceeding ahead.*/

SELECT 
CONVERT(DATE, DOB, 105) AS CUST_DATES 
FROM CUSTOMER 
SELECT 
CONVERT(DATE, TRAN_DATE, 105) AS TRAN_DATE
FROM TRANSACTIONS;

/* 4. What is the time range of the transaction data available for analysis? Show the output in number of days, months and years simultaneously
	in different columns. */
	
SELECT 
DATEDIFF(DAY, MIN(CONVERT(DATE, TRAN_DATE, 105)), MAX(CONVERT(DATE, TRAN_DATE, 105))) AS TRAN_DAYS , 
DATEDIFF(MONTH, MIN(CONVERT(DATE, TRAN_DATE, 105)), MAX(CONVERT(DATE, TRAN_DATE, 105))) TRAN_MONTHS,  
DATEDIFF(YEAR, MIN(CONVERT(DATE, TRAN_DATE, 105)), MAX(CONVERT(DATE, TRAN_DATE, 105))) TRAN_YEARS 
FROM TRANSACTIONS;

-- 5. Which product category does the sub-category “DIY” belong to?

SELECT 
PROD_CAT
FROM 
PROJEC_CAT_INFO
WHERE
PROD_SUBCAT LIKE 'DIY';

--DATA ANALYSIS
-- 1. Which channel is most frequently used for transactions?

SELECT 
TOP 1 
STORE_TYPE, COUNT(TRANSACTION_ID) AS Count_
FROM 
TRANSACTIONS
GROUP BY 
STORE_TYPE
ORDER BY 
COUNT(TRANSACTION_ID) DESC;

--2. What is the count of Male and Female customers in the database?

SELECT 
GENDER, COUNT(CUSTOMER_ID) AS COUNT_GENDER
FROM
CUSTOMER
WHERE 
GENDER IN ('M' , 'F')
GROUP BY
GENDER;

--3. From which city do we have the maximum number of customers and how many?

SELECT 
TOP 1
CITY_CODE, COUNT(CUSTOMER_ID) CUST_CNT
FROM CUSTOMER
GROUP BY 
CITY_CODE
ORDER BY
CUST_CNT DESC;


--4. How many sub-categories are there under the Books category?

SELECT 
COUNT(PROD_SUBCAT) AS SUBCATEGORY_COUNT
FROM
PROJEC_CAT_INFO
WHERE 
PROD_CAT = 'BOOKS'
GROUP BY
PROD_CAT;

--5. What is the maximum quantity of products ever ordered?

SELECT 
MAX(Qty) AS 
max_quantity_ordered
FROM 
Transactions;


--6.	What is the net total revenue generated in categories Electronics and Books?

SELECT SUM(TOTAL_AMT) AMOUNT
FROM transactions as t
INNER JOIN projec_cat_info as pci ON pci.prod_cat_code = t.prod_cat_code
AND prod_sub_cat_code = prod_subcat_code
WHERE PROD_CAT IN ('BOOKS' , 'ELECTRONICS');


--7.	How many customers have >10 transactions with us, excluding returns?

SELECT COUNT(DISTINCT t.cust_id) AS num_customers
FROM (
    SELECT cust_id
    FROM Transactions
    WHERE total_amt > 0
    GROUP BY cust_id
    HAVING COUNT(transaction_id) > 10
) AS t;


--8.	What is the combined revenue earned from the “Electronics” & “Clothing” categories, from “Flagship stores”?

SELECT SUM(t.total_amt) AS combined_revenue
FROM Transactions t
JOIN projec_cat_info p
ON t.prod_cat_code = p.prod_cat_code
WHERE p.prod_cat IN ('Electronics', 'Clothing')
AND t.Store_type = 'Flagship store';


/* 9.	What is the total revenue generated from “Male” customers 
	in “Electronics” category? Output should display total revenue by 
	prod sub-cat. */

SELECT p.prod_cat, prod_subcat_code, SUM(total_amt) AS REVENUE
FROM transactions
LEFT JOIN CUSTOMER c ON CUST_ID=CUSTOMER_ID
LEFT JOIN projec_cat_info p ON prod_sub_cat_code = PROD_SUBCAT_CODE AND p.prod_cat_code = p.prod_cat_code
WHERE p.prod_cat_code= '3' AND GENDER = 'M'
GROUP BY p.prod_cat,PROD_SUBCAT_CODE, PROD_SUBCAT;

--10. What is percentage of sales and returns by product sub category; display only top 5 sub categories in terms of sales? 

WITH SubCategorySales AS (
    SELECT 
        p.prod_sub_cat_code,
        p.prod_subcat,
        SUM(CASE WHEN t.total_amt > 0 THEN t.total_amt ELSE 0 END) AS total_sales,
        SUM(CASE WHEN t.total_amt < 0 THEN ABS(t.total_amt) ELSE 0 END) AS total_returns
    FROM Transactions t
    JOIN projec_cat_info p ON t.prod_cat_code = p.prod_cat_code AND t.prod_subcat_code = p.prod_sub_cat_code
    GROUP BY p.prod_sub_cat_code, p.prod_subcat
),
RankedSales AS (
    SELECT 
        prod_sub_cat_code,
        prod_subcat,
        total_sales,
        total_returns,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM SubCategorySales
)
SELECT 
    prod_subcat,
    total_sales,
    total_returns,
    (total_sales / (total_sales + total_returns) * 100) AS sales_percentage,
    (total_returns / (total_sales + total_returns) * 100) AS returns_percentage
FROM RankedSales
WHERE sales_rank <= 5;

/* 11.	For all customers aged between 25 to 35 years find what is the 
	net total revenue generated by these consumers in last 30 days of transactions
	from max transaction date available in the data? */

SELECT cust_id ,SUM(total_amt) AS REVENUE FROM transactions
WHERE CUST_ID IN 
	(SELECT CUSTOMER_ID
	 FROM CUSTOMER
     WHERE DATEDIFF(YEAR,CONVERT(DATE,DOB,103),GETDATE()) BETWEEN 25 AND 35)
     AND CONVERT(DATE,tran_date,103) BETWEEN DATEADD(DAY,-30,(SELECT MAX(CONVERT(DATE,tran_date,103)) FROM transactions)) 
	 AND (SELECT MAX(CONVERT(DATE,tran_date,103)) FROM transactions)
GROUP BY CUST_ID;


/* 12.	Which product category has seen the max value of returns in the last 3 
	months of transactions? */

SELECT TOP 1 
    T2.prod_cat, 
    SUM(T1.total_amt) AS total_returns
FROM transactions T1
INNER JOIN projec_cat_info T2 
    ON T1.prod_cat_code = T2.prod_cat_code 
    AND T1.prod_subcat_code = T2.prod_sub_cat_code
WHERE T1.total_amt < 0 
  AND CONVERT(DATE, T1.tran_date, 103) BETWEEN DATEADD(MONTH, -3, 
        (SELECT MAX(CONVERT(DATE, tran_date, 103)) FROM transactions)) 
        AND (SELECT MAX(CONVERT(DATE, tran_date, 103)) FROM transactions)
GROUP BY T2.prod_cat
ORDER BY total_returns DESC;




/* 13.	Which store-type sells the maximum products; by value of sales amount and
	by quantity sold? */

SELECT  STORE_TYPE, SUM(TOTAL_AMT) TOT_SALES, SUM(QTY) TOT_QUAN
FROM transactions
GROUP BY STORE_TYPE
HAVING SUM(TOTAL_AMT) >=ALL (SELECT SUM(TOTAL_AMT) FROM transactions GROUP BY STORE_TYPE)
AND SUM(QTY) >=ALL (SELECT SUM(QTY) FROM transactions GROUP BY STORE_TYPE);
 

/* 14.	What are the categories for which average revenue is above the overall average. */

SELECT PROD_CAT, AVG(TOTAL_AMT) AS AVERAGE
FROM transactions t
INNER JOIN projec_cat_info p ON p.prod_cat_code = t.prod_cat_code AND prod_sub_cat_code = PROD_SUBCAT_CODE
GROUP BY PROD_CAT
HAVING AVG(TOTAL_AMT)> (SELECT AVG(TOTAL_AMT) FROM transactions) ;


/* 15.	Find the average and total revenue by each subcategory for the categories 
	which are among top 5 categories in terms of quantity sold. */

SELECT 
    p.prod_cat,
    t.prod_cat_code, 
    t.prod_subcat_code, 
    AVG(t.total_amt) AS average_revenue, 
    SUM(t.total_amt) AS total_revenue
FROM transactions t
INNER JOIN projec_cat_info p 
    ON t.prod_cat_code = p.prod_cat_code 
    AND t.prod_subcat_code = p.prod_sub_cat_code
WHERE t.prod_cat_code IN (
    SELECT TOP 5 
        t.prod_cat_code
    FROM transactions t
    INNER JOIN projec_cat_info p 
        ON t.prod_cat_code = p.prod_cat_code 
        AND t.prod_subcat_code = p.prod_sub_cat_code
    GROUP BY t.prod_cat_code
    ORDER BY SUM(t.qty) DESC
)
GROUP BY p.prod_cat,t.prod_cat_code, t.prod_subcat_code;

