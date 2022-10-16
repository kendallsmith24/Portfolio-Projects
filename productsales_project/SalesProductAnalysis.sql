USE SalesproductAnalysis;

/* ----------------------------------------------------------- */
/* ------------------ DATABASE DESIGN ------------------------ */
/* ----------------------------------------------------------- */

/* CREATING A TABLE THAT INCLUDES ALL MONTH'S DATA THAT WILL BE RUN INTO THE SALES TABLE */
/* USED UNION TO REMOVE ANY DUPLICATES ROWS THAT MAY EXIST BETWEEN THE TABLES */

DROP TABLE IF EXISTS sales2019;

SELECT * INTO sales2019
FROM
(SELECT * FROM Sales_January_2019
UNION
SELECT * FROM Sales_February_2019
UNION
SELECT * FROM Sales_March_2019
UNION
SELECT * FROM Sales_April_2019
UNION
SELECT * FROM Sales_May_2019
UNION
SELECT * FROM Sales_June_2019
UNION
SELECT * FROM Sales_July_2019
UNION
SELECT * FROM Sales_August_2019
UNION
SELECT * FROM Sales_September_2019
UNION
SELECT * FROM Sales_October_2019
UNION
SELECT * FROM Sales_November_2019
UNION
SELECT * FROM Sales_December_2019) AS sales2019;

SELECT TOP (5) * FROM sales2019;

/* RENAME COLUMNS IN sales2019 TABLE */ 

EXEC sp_RENAME 'sales2019.Order ID','order_id','COLUMN';
EXEC sp_RENAME 'sales2019.product','product','COLUMN';
EXEC sp_RENAME 'sales2019.Quantity Ordered','qty_ordered','COLUMN';
EXEC sp_RENAME 'sales2019.Price Each','price_each','COLUMN';
EXEC sp_RENAME 'sales2019.Order Date','order_date','COLUMN';
EXEC sp_RENAME 'sales2019.Purchase Address','purchase_address','COLUMN';

/* CHECKING THE DATA TYPES FOR THE COLUMNS IN THE sales2019 TABLE */

SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sales2019';

/* CHANGE THE DATA TYPES FOR THE COLUMNS ACCORDINGLY */

ALTER TABLE sales2019
ALTER COLUMN order_id INT;

ALTER TABLE sales2019
ALTER COLUMN product VARCHAR(255);

ALTER TABLE sales2019
ALTER COLUMN qty_ordered INT;

ALTER TABLE sales2019
ALTER COLUMN price_each FLOAT;

ALTER TABLE sales2019
ALTER COLUMN order_date DATETIME;

ALTER TABLE sales2019
ALTER COLUMN purchase_address VARCHAR(255);


/* FINDING DUPLICATE ROWS IN THE sales2019 TABLE */

WITH duplicates AS
				(SELECT order_id, product, price_each, order_date, purchase_address,
				ROW_NUMBER() OVER (
				PARTITION BY order_id, product, price_each, order_date, purchase_address
				ORDER BY order_id, product, price_each, order_date, purchase_address)  AS ROW_NUM
				FROM sales2019)
SELECT * FROM duplicates WHERE ROW_NUM > 1;

SELECT * FROM sales2019 WHERE order_id IN (154215, 155031, 159804);


-- TAKING A LOOK AT ONE OF THE DUPLICATES 'order_id = 154215' THE FOLLOWING ERROR POPULATES --
-- Msg 245, Level 16, State 1, Line 53 -- 
-- Conversion failed when converting the varchar value 'Order ID' to data type int. -- 
-- INDICATES THAT THERE ARE VALUES IN THE order_id COLUMN THAT ARE NOT AN INTEGER -- 

SELECT * FROM sales2019 WHERE order_id = 154215;

SELECT order_id, product, SUM(qty_ordered), price_each, order_date, purchase_address
FROM sales2019 WHERE order_id = 154215	GROUP BY order_id, product, price_each, order_date, purchase_address


-- FINDING ROWS IN sales2019 COLUMN WHERE order_id IS NOT AN INTEGER -- 

SELECT * FROM sales2019 WHERE order_id NOT LIKE '%[0-9]%';

-- DELETING ROWS IN sales2019 COLUMN WHERE order_id IS NOT AN INTEGER -- 

DELETE FROM sales2019 WHERE order_id NOT LIKE '%[0-9]%';

-- DELETING DUPLICATE ROWS IN THE sales2019 TABLE --
WITH duplicates AS
				(SELECT order_id, product, qty_ordered, price_each, order_date, purchase_address,
				ROW_NUMBER() OVER (
				PARTITION BY order_id, product, qty_ordered, price_each, order_date, purchase_address
				ORDER BY order_id, product, qty_ordered, price_each, order_date, purchase_address)  AS ROW_NUM
				FROM sales2019)
DELETE FROM duplicates WHERE ROW_NUM > 1;

SELECT * 
FROM sales2019;


-- REMOVING QUOTATIONS THAT APPEAR AROUND THE ADDRESS IN THE Purchase Address COLUMN -- 

SELECT REPLACE(purchase_address,'"','') 
FROM sales2019;

UPDATE sales2019
SET [purchase_address] = REPLACE([purchase_address], '"','');



/* CREATING THE SALES TABLE FOR THE DATABASE */

DROP TABLE IF EXISTS sales
CREATE TABLE sales (
sales_id UNIQUEIDENTIFIER DEFAULT NEWSEQUENTIALID() NOT NULL PRIMARY KEY,
order_id INT,
product VARCHAR(255),
qty_ordered INT, 
price_each FLOAT, 
order_date DATETIME,
purchase_address VARCHAR(255))

SELECT * FROM sales;

INSERT INTO sales (order_id, product, qty_ordered, price_each, order_date, purchase_address)
SELECT order_id, product, SUM(qty_ordered), price_each, order_date, purchase_address
FROM sales2019
GROUP BY order_id, product, price_each, order_date, purchase_address;

SELECT * FROM sales;


SELECT order_id, ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_id) AS ROW_NUM
FROM sales 
ORDER BY ROW_NUM DESC;

SELECT * FROM sales WHERE order_id = 160873;

SELECT TOP (5) * FROM sales;


/* CREATE THE CUSTOMER TABLE */


DROP TABLE IF EXISTS customers
CREATE TABLE customers (
customer_id INT IDENTITY(100000, 1) PRIMARY KEY,
purchase_address VARCHAR(255) NOT NULL);

SELECT * FROM customers

-- STORING UNIQUE VALUES IN purchase_address COLUMN FROM THE SALES TABLE --
-- THEN PARSING RESULTS TO INSERT INTO THE OTHER CUSTOMER TABLE FIELDS -- 

INSERT INTO customers (purchase_address)
SELECT DISTINCT purchase_address
FROM sales;

SELECT * FROM customers;

ALTER TABLE customers
ADD address_name VARCHAR(255);

ALTER TABLE customers
ADD city VARCHAR(255);

ALTER TABLE customers
ADD address_state VARCHAR(10);

ALTER TABLE customers
ADD zip_code VARCHAR(10); 

UPDATE customers
SET address_name = PARSENAME(REPLACE(purchase_address,',','.'),3);

UPDATE customers
SET city = PARSENAME(REPLACE(purchase_address,',','.'),2);

UPDATE customers
SET address_state = PARSENAME(REPLACE(purchase_address,',','.'),1);

-- 2ND UPDATE TO address_state COLUMN TO REMOVE ZIP CODE -- 
UPDATE customers
SET address_state = PARSENAME(REPLACE(address_state,' ','.'),2);

UPDATE customers
SET zip_code = REVERSE(PARSENAME(REPLACE(REVERSE(purchase_address),',','.'),3));

-- 2ND UPDATE TO zip_code COLUMN TO REMOVE address_state -- 
UPDATE customers
SET zip_code = PARSENAME(REPLACE(zip_code,' ','.'),1);

SELECT TOP (5) * FROM customers;

/* CREATE THE PRODUCT TABLE */

-- STORING UNIQUE VALUES IN THE product COLUMN --

DROP TABLE IF EXISTS product
CREATE TABLE product(
product_id INT IDENTITY(1, 1),
product VARCHAR(255) NOT NULL PRIMARY KEY, 
unit_price FLOAT);

-- STORING UNIQUE VALUES IN product COLUMN FROM SALES TABLE WITHIN CTE NAMED item --
-- THEN INSERT RESULTS INTO PRODUCT TABLE -- 

WITH item AS (
		SELECT DISTINCT product, CAST(price_each AS FLOAT) AS price_each
		FROM sales)
INSERT INTO product (product, unit_price)
SELECT product, price_each FROM item;

SELECT * FROM product;

/* CREATING MONTH, DAY, AND YEAR COLUMNS IN THE SALES TABLE FROM THE order_date COLUMN */
 
ALTER TABLE sales
ADD date_month INT;

UPDATE sales
SET date_month = MONTH(order_date) FROM sales;

ALTER TABLE sales
ADD date_day INT;

UPDATE sales
SET date_day = DAY(order_date) FROM sales;

ALTER TABLE sales
ADD date_year INT;

UPDATE sales
SET date_year = YEAR(order_date) FROM sales;

/* ASSIGNING FOREIGN KEYS */

ALTER TABLE sales
ADD FOREIGN KEY (product) REFERENCES product (product);

/* VIEWS */

-- CREATING AN ORDERS VIEW -- 
-- ORDER VIEW WILL SHOW ALL ORDER IDS, CUSTOMER IDS ASSOCIATED WITH ORDERS, ALL PRODUCTS IN ORDER TOGETHER --
-- ,NUMBER OF ITEMS, ORDER TOTAL, AND PURCHASE ADDRESS --

CREATE VIEW orders
AS 
SELECT DISTINCT s.order_id, c.customer_id, STRING_AGG(s.product,'/') AS all_products, 
SUM(s.qty_ordered) AS NumberofItems, SUM (s.qty_ordered*s.price_each) AS CompleteOrderTotal, s.purchase_address
FROM sales AS s
JOIN customers AS c
ON s.purchase_address = c.purchase_address
GROUP BY order_id, c.customer_id, s.purchase_address;

SELECT * FROM orders

SELECT all_products, COUNT(all_products), ROUND(SUM(CompleteOrderTotal),0) FROM orders
GROUP BY all_products ORDER BY all_products DESC

/* ----------------------------------------------------------- */
/* ------------------ PRODUCT SALES ANALYSIS ----------------- */
/* ----------------------------------------------------------- */


-- BASIC CUSTOMER BREAKDOWN INFORMATION -- 

-- FINDING THE NUMBER OF CUSTOMERS IN EACH STATE -- 

SELECT address_state, COUNT(customer_id) AS 'number of customers'
FROM customers
GROUP BY address_state
ORDER BY address_state;

-- SEEING THE BREAKDOWN OF NUMBER OF CUSTOMERS BY CITY -- 

SELECT city AS 'City', address_state AS 'State', COUNT(customer_id) AS 'Number of Customers'
FROM customers
GROUP BY city, address_state
ORDER BY address_state, city;


-- FINDING THE MONTHLY SALES TOTALS -- 

SELECT date_month, ROUND(SUM(qty_ordered*price_each),2) AS 'monthly totals'
FROM sales
GROUP BY date_month
ORDER BY date_month;


-- FINDING THE SALES TOTALS FOR EACH PRODUCT FOR EACH MONTH --

SELECT product, date_month, ROUND(SUM(qty_ordered*price_each),2) AS 'monthly_product_sales'
FROM sales
GROUP BY product, date_month
ORDER BY product, date_month;


-- FINDING THE SALES TOTALS FOR EACH STATE --

SELECT c.address_state, ROUND(SUM(s.qty_ordered*s.price_each),2) AS 'sales_totals'
FROM customers AS c
JOIN sales AS s
ON c.purchase_address = s.purchase_address
GROUP BY c.address_state
ORDER BY c.address_state;

-- FINDING THE SALES TOTALS FOR EACH CITY --

SELECT c.city, c.address_state, ROUND(SUM(s.qty_ordered*s.price_each),2) AS 'sales_totals'
FROM customers AS c
JOIN sales AS s
ON c.purchase_address = s.purchase_address
GROUP BY c.city, c.address_state
ORDER BY c.city, c.address_state;

-- BREAKDOWN THE SALES TOTALS FOR EACH STATE PER MONTH --

SELECT c.address_state, s.date_month, ROUND(SUM(s.qty_ordered*s.price_each),2) AS 'sales_totals'
FROM customers AS c
JOIN sales AS s
ON c.purchase_address = s.purchase_address
GROUP BY c.address_state, s.date_month
ORDER BY c.address_state, s.date_month;

--- CONVERTED INTO PIVOT FOR BETTER QUERY RESULT READABILITY ---


SELECT *, CA + GA + MA + ME + NY + [OR] + TX + WA AS month_totals 
FROM 
	(SELECT c.address_state, s.date_month AS 'month', 
	CAST((s.qty_ordered*s.price_each) AS DECIMAL(10,2)) AS 'sales_totals'
	FROM sales AS s
	JOIN customers AS c
	ON s.purchase_address = c.purchase_address) AS t
PIVOT
(
	SUM(t.sales_totals)
	FOR address_state IN (CA, GA, MA, ME, NY, [OR], TX, WA))
AS pivot_table
ORDER BY 'month';

-- COMPARING THE SALES OF THE CURRENT MONTH WITH THE PREVIOUS MONTH FOR EACH STATE ALONG WITH PERCENTAGE CHANGE --

WITH state_sales AS(
		SELECT c.address_state, s.date_month, ROUND(SUM(s.qty_ordered*s.price_each),2) AS 'sales_totals',
		LAG(ROUND(SUM(s.qty_ordered*s.price_each),2)) OVER (PARTITION BY address_state ORDER BY date_month) AS 'previous_month_sales'
		FROM customers AS c
		JOIN sales AS s
		ON c.purchase_address = s.purchase_address
		GROUP BY c.address_state, s.date_month) 
SELECT address_state AS 'state', date_month AS 'month', sales_totals, previous_month_sales,
FORMAT((sales_totals-previous_month_sales) / previous_month_sales,'P') AS pct_change
FROM state_sales;

-- COMPARING THE SALES OF THE CURRENT MONTH WITH THE PREVIOUS MONTH ALONG WITH PERCENTAGE CHANGE --

WITH month_sales AS(
		SELECT date_month, ROUND(SUM(qty_ordered*price_each),2) AS 'sales_totals',
		LAG(ROUND(SUM(qty_ordered*price_each),2)) OVER (ORDER BY date_month) AS 'previous_month_sales'
		FROM sales
		GROUP BY date_month) 
SELECT date_month AS 'month', sales_totals, previous_month_sales,
FORMAT((sales_totals-previous_month_sales) / previous_month_sales,'P') AS pct_change
FROM month_sales;

-- FINDING THE TOTAL NUMBER OF EACH PRODUCT ORDERED EACH MONTH --

SELECT product, date_month, SUM(qty_ordered) AS 'total_qty_ordered'
FROM sales
GROUP BY product, date_month
ORDER BY product, date_month;


-- FINDING THE TOTAL NUMBER OF EACH PRODUCT ORDERED FOR ENTIRE YEAR --

SELECT product, SUM(qty_ordered) AS 'total_ordered'
FROM sales
GROUP BY product
ORDER BY product;

-- FINDING THE AMOUNT OF EACH PRODUCT SOLD IN EACH STATE -- 

SELECT c.address_state, s.product, SUM(s.qty_ordered) AS inventory_sold
FROM sales AS s
JOIN customers AS c
ON s.purchase_address = c.purchase_address
GROUP BY c.address_state, s.product
ORDER BY address_state

-- FINDING THE NUMBER OF EACH PRODUCT SOLD IN EACH STATE + TOTALS --
-- USING PIVOT FOR BETTER QUERY RESULT READABILITY -- 

SELECT *, CA + GA + MA + ME + NY + [OR] + TX + WA AS total_units_sold
FROM 
	(SELECT c.address_state, s.product, s.qty_ordered AS inventory_sold
	FROM sales AS s
	JOIN customers AS c
	ON s.purchase_address = c.purchase_address) AS t
PIVOT
(
	SUM(t.inventory_sold)
	FOR address_state IN (CA, GA, MA, ME, NY, [OR], TX, WA))
AS pivot_table
ORDER BY product;


-- FINDING AVERAGE SALES TOTALS IN EACH STATE --
SELECT c.address_state AS 'State', (ROUND(AVG(s.qty_ordered*s.price_each),2)) AS 'Average Order Totals-State'
FROM customers AS c
JOIN sales AS s
ON c.purchase_address = s.purchase_address
GROUP BY c.address_state
ORDER BY c.address_state;

-- FINDING AVERAGE SALES TOTALS IN EACH CITY --

SELECT c.city AS 'City', (ROUND(AVG(s.qty_ordered*s.price_each),2)) AS 'Average Order Total-City'
FROM customers AS c
JOIN sales AS s
ON c.purchase_address = s.purchase_address
GROUP BY c.city
ORDER BY c.city;


-- TOTAL NUMBER OF ORDERS IN EACH STATE --

SELECT c.address_state AS 'State', COUNT(s.order_id) AS 'Total Number of Orders-State'
FROM customers AS c
JOIN sales AS s
ON c.purchase_address = s.purchase_address
GROUP BY c.address_state
ORDER BY c.address_state;

-- TOTAL NUMBER OF ORDERS IN EACH CITY --

SELECT c.city AS 'City', c.address_state AS 'State', COUNT(s.order_id) AS 'Total Number of Orders-City'
FROM customers AS c
JOIN sales AS s
ON c.purchase_address = s.purchase_address
GROUP BY c.city, c.address_state
ORDER BY c.city, c.address_state;


-- FINDING THE STATES WHERE YEARLY SALES TOTALS WERE GREATER THAN THE YEARLY AVERAGE SALES OF ENTIRE MARKET (ALL STATES) -- 

WITH yearly_sales AS 
			(SELECT c.address_state, CAST(SUM(s.qty_ordered*s.price_each) AS INT) AS 'state_sales_totals'
			FROM customers AS c
			JOIN sales AS s
			ON c.purchase_address = s.purchase_address
			GROUP BY c.address_state),
	avg_sales AS 
			(SELECT AVG(state_sales_totals) AS 'market_avg_sales'
			FROM yearly_sales)
SELECT *, (yearly_sales.state_sales_totals - avg_sales.market_avg_sales) AS 'Sales_Amt_over_Avg'
FROM yearly_sales
JOIN avg_sales
ON yearly_sales.state_sales_totals > avg_sales.market_avg_sales;


-- BASED ON THE STATE WHERE YEARLY SALES TOTALS GREATER THAN YEARLY AVERAGE SALES (ENTIRE MARKET) --
-- TAKING A LOOK AT THE TOTAL INVENTORY SOLD AND SALES OF EACH product IN EACH OF THOSE STATES -- 
-- USING ROLLUP FOR SUBTOTALS -- 

SELECT COALESCE(c.address_state, 'All States Totals') AS 'top_states', COALESCE(s.product, 'All products') AS 'product', 
SUM(s.qty_ordered) AS 'inventory_sold',
ROUND(SUM(s.price_each*s.qty_ordered),0) AS 'total_sales'
FROM sales AS s
JOIN customers AS c
ON s.purchase_address = c.purchase_address
WHERE c.address_state IN ('CA', 'NY', 'TX')
GROUP BY ROLLUP (s.product, c.address_state);


-- FINDING THE TOTAL SALES OF EACH PRODUCT WITHIN EACH STATE WITH FINAL TOTAL --
-- REPRESENTED AS PIVOT TABLE -- 

SELECT *, CA + GA + MA + ME + NY + [OR] + TX + WA AS total_sales 
FROM 
	(SELECT c.address_state, s.product, CAST((s.qty_ordered*s.price_each) AS DECIMAL(10,2)) AS 'sales_totals'
	FROM sales AS s
	JOIN customers AS c
	ON s.purchase_address = c.purchase_address) AS t
PIVOT
(
	SUM(t.sales_totals)
	FOR address_state IN (CA, GA, MA, ME, NY,[OR],TX, WA))
AS pivot_table
ORDER BY total_sales DESC;


-- FINDING THE CUSTOMERS WITH THE HIGHEST NUMBER OF ORDERS (INCLUDING THE CITY, STATE) FOR THE ENTIRE YEAR (2019) -- 

SELECT TOP 5 c.customer_id, c.city, c.address_state, COUNT(DISTINCT s.order_id) AS 'Total Orders'
FROM sales AS s
JOIN customers AS c
ON s.purchase_address = c.purchase_address
GROUP BY city, address_state, customer_id 
ORDER BY 'Total Orders' DESC;

-- FINDING THE TOP 10 PAIRED PRODUCTS WITH COUNT AND SALES TOTAL -- 

SELECT TOP(10) all_products, COUNT(NumberofItems) AS 'Count', ROUND(SUM(CompleteOrderTotal),0) AS 'Total' 
FROM orders 
WHERE all_products LIKE '%/%' 
GROUP BY all_products 
ORDER BY 'Count' DESC


/* ----------------------------------------------------------- */
/* ---------------------- MISCELLANEOUS ---------------------- */
/* ----------------------------------------------------------- */


/* FINDING THE PRICE FOR EACH PRODUCT IN EACH STATE */
/* LATER TO ADD THE CURRENT STATE SALES TAX TO CREATE ACTUAL COST COLUMN TO product TABLE */

SELECT DISTINCT p.product_id, p.product, p.unit_price, c.address_state
FROM product AS p
JOIN sales AS s
ON p.product = s.product
JOIN customers AS c
ON s.purchase_address = c.purchase_address
ORDER BY p.product_id;

/* CREATING STATE SALES TAX TABLE */

CREATE TABLE #Sales_Tax(
address_state CHAR(2),
sales_tax DECIMAL(3,2));

INSERT INTO #Sales_Tax (address_state, sales_tax)
VALUES ('CA', 7.25)

INSERT INTO #Sales_Tax (address_state, sales_tax)
VALUES ('GA', 4)

INSERT INTO #Sales_Tax (address_state, sales_tax)
VALUES ('MA', 6.25)

INSERT INTO #Sales_Tax (address_state, sales_tax)
VALUES ('ME', 5.5)

INSERT INTO #Sales_Tax (address_state, sales_tax)
VALUES ('NY', 4)

INSERT INTO #Sales_Tax (address_state, sales_tax)
VALUES ('OR', 0)

INSERT INTO #Sales_Tax (address_state, sales_tax)
VALUES ('TX', 6.25)

INSERT INTO #Sales_Tax (address_state, sales_tax)
VALUES ('WA', 6.5)

SELECT * 
FROM #Sales_Tax;

-- DETERMINING THE ACTUAL COST OF EACH PRODUCT ADDING THE STATE SALES TAX TO THE PRICE --
-- USING CTEs, CASE STATEMENT, JOINS, AND TEMP TABLE -- 


WITH CTE_price AS
			(SELECT DISTINCT p.product_id, p.product, p.unit_price, c.address_state
			FROM product AS p
			JOIN sales AS s
			ON p.product = s.product
			JOIN customers AS c
			ON s.purchase_address = c.purchase_address),
	CTE_tax AS
			(SELECT product_id, product, unit_price, t.sales_tax, t.address_state,
			CASE
				WHEN CTE_price.address_state = t.address_state THEN ROUND((unit_price + ((t.sales_tax*unit_price)/100)),2)
				-- WHEN ADDRESS STATE FROM CTE_1 MATCHES THE ADDRESS STATE IN THE SALES TAX TEMP TABLE, THE EQUATION --
				-- INPUTS THE CORRESPONDING STATE TAX TO RETURN THE ACTUAL COST OF THE PRODUCT --
				ELSE 0
			END AS actual_cost
			FROM CTE_price
			JOIN #Sales_Tax AS t
			ON t.address_state = CTE_price.address_state)
SELECT *
FROM CTE_tax
ORDER BY address_state, product_id;


/* CREATING A MEMBERSHIP REWARDS TABLE */ 

CREATE TABLE #Rewards (
MembershipType CHAR(255),
OverallDiscountPct INT,
OrdersGreaterthan100 INT,
OrdersGreaterthan500 INT);


INSERT INTO #Rewards (MembershipType, OverallDiscountPct, OrdersGreaterthan100, OrdersGreaterthan500)
VALUES ('Silver', 5, 5, 10);

INSERT INTO #Rewards (MembershipType, OverallDiscountPct, OrdersGreaterthan100, OrdersGreaterthan500)
VALUES ('Gold', 7, 10, 12);

INSERT INTO #Rewards (MembershipType, OverallDiscountPct, OrdersGreaterthan100, OrdersGreaterthan500)
VALUES ('VIP', 10, 12, 15);

SELECT * FROM #Rewards;


-- DETERMINING REWARDS MEMBERSHIP CANDIDACY BASED ON YEAR END PURCHASE TOTALS FOR EACH CUSTOMER (EXCLUDES SALES TAX) --
 
SELECT c.customer_id, SUM(s.qty_ordered*s.price_each) AS 'year_end_totals',
	CASE
		WHEN SUM(s.qty_ordered*s.price_each) > 2500 THEN NCHAR(10004) -- NCHAR(10004) IS CHECKMARK --
		ELSE NCHAR(10008) -- NCHAR(10008) IS 'X' MARK -- 
	END AS VIP,
	CASE
		WHEN SUM(s.qty_ordered*s.price_each) >= 1000 THEN NCHAR(10004)
		ELSE NCHAR(10008)
	END AS Gold,
	CASE 
		WHEN SUM(s.qty_ordered*s.price_each) >= 500 THEN NCHAR(10004)
		ELSE NCHAR(10008)
	END AS Silver
FROM customers AS c
JOIN sales AS s
ON c.purchase_address = s.purchase_address
GROUP BY c.customer_id
ORDER BY c.customer_id;




