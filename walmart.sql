CREATE SCHEMA IF NOT EXISTS walmart ;
# specify which schema we will use
USE walmart; 
CREATE TABLE sales(
	invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(30) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    tax_pct FLOAT NOT NULL,
    total DECIMAL(12, 4) NOT NULL,
    date DATETIME NOT NULL,
    time TIME NOT NULL,
    payment VARCHAR(15) NOT NULL,
    cogs DECIMAL(10,2) NOT NULL,
    gross_margin_pct FLOAT,
    gross_income DECIMAL(12, 4),
    rating FLOAT
);
SELECT * FROM sales;

-- -- feature engineering with SQL
-- month of each transaction 
ALTER TABLE sales ADD COLUMN month VARCHAR(10);

#SET SQL_SAFE_UPDATES = 0; ignore this since I set the safe update mode

UPDATE sales
SET month = MONTHNAME(date);


-- day of the transaction 
ALTER TABLE sales ADD COLUMN day VARCHAR(10);

UPDATE sales
SET day = DAYNAME(date);


-- time period of the day 
ALTER TABLE sales ADD COLUMN period VARCHAR(10);

UPDATE sales
SET period = 
    CASE
        WHEN HOUR("time") BETWEEN 0 AND 11 THEN "Morning"
        WHEN HOUR("time") BETWEEN 12 AND 15 THEN "Afternoon"
        ELSE "Evening"
    END;
    
-- Exploratory Data Analysis of sales and product of walmart 
-- we are going to answer the following easy and advanced questions with SQL. 

# 1.) How many branches/ productline/ payment are there and what are them?

SELECT COUNT(DISTINCT branch) AS num_branches, 
       GROUP_CONCAT(DISTINCT branch ORDER BY branch) AS branch_names
FROM sales;

SELECT COUNT(DISTINCT product_line) AS num_product,
       GROUP_CONCAT(DISTINCT product_line ORDER BY product_line) AS product
FROM sales;

SELECT COUNT(DISTINCT payment) AS num_payment, 
       GROUP_CONCAT(DISTINCT payment ORDER BY payment) AS payment_methods
FROM sales;

# 2.) how many unique customers in each branch? 
SELECT branch, 
       COUNT(DISTINCT(invoice_id))
FROM sales
GROUP BY branch;
-- It is not varied much in each branch (A:340, B:332, C:328)

# 3.) which type of customer create the most revenues? 
SELECT customer_type, 
	   SUM(total) AS revenues 
FROM sales 
GROUP BY customer_type
ORDER BY revenues DESC
LIMIT 1;
-- member customer make a bit more than normal customers.  ( 164223.4440 and 158743.3050)

# 4.) Average Quantity, Revenue per transaction by Gender and Product Line
SELECT product_line,gender,
       AVG(quantity) AS avg_quantity, 
       AVG(total) AS avg_revenue
FROM sales
GROUP BY gender, product_line
ORDER BY product_line, gender;

# 5.) Provide revenues/profit generated in each branch and find which branch generated highest? 
SELECT branch, 
       SUM(total) AS revenues, 
       SUM(gross_income) AS profit
FROM sales
GROUP BY branch
ORDER BY revenues DESC, profit DESC; 
-- A: 106200.3705, 5057.1605, B: 106197.6720,5057.0320, C:110568.7065,5265.1765

-- To find the max revenues and profit, we use limit and order by 
SELECT branch, 
       revenues, 
       profit 
FROM (
    SELECT branch, 
           SUM(total) AS revenues, 
           SUM(gross_income) AS profit
    FROM sales
    GROUP BY branch
    ORDER BY revenues DESC, profit DESC
) AS ate
LIMIT 1;

-- we can see that C is the most profitable () and generate the higehst revenues 

# 6.) Provide revenues/profit generated in each month/day/period and find which time is the highest?
-- month January(116291.8680,5537.7080), February (97219.3740,4629.4940), March(109455.5070,5212.1670)
SELECT month, 
       SUM(total) AS revenues, 
       SUM(gross_income) AS profit
FROM sales
GROUP BY month
ORDER BY revenues DESC, profit DESC;

-- Which month generate the highest and how much
SELECT month, 
	   SUM(total) AS revenues, 
       SUM(gross_income) AS profit
FROM sales
GROUP BY month
ORDER BY revenues DESC, profit DESC
LIMIT 1 ;

-- If we only want month for the result
SELECT month
FROM (
    SELECT month, 
           SUM(total) AS revenues, 
           SUM(gross_income) AS profit
    FROM sales
    GROUP BY month
    ORDER BY revenues DESC, profit DESC
) AS ate
LIMIT 1;

-- Day (saturday,56120.8095,2672.4195 ), Tuesday(51482.2455,2451.5355), 
SELECT day, 
       SUM(total) AS revenues, 
       SUM(gross_income) AS profit
FROM sales
GROUP BY day
ORDER BY revenues DESC, profit DESC;

-- Period of the day, evening (138370.9215,6589.0915), afternoon(122797.0170,5847.4770), morning(61798.8105,2942.8005)
SELECT period, 
       SUM(total) AS revenues, 
       SUM(gross_income) AS profit
FROM sales
GROUP BY period
ORDER BY revenues DESC, profit DESC;

# 7.) Average rating by store
SELECT branch, 
       AVG(rating)
FROM sales
GROUP BY branch;
-- B has the lowest rating

# 8.) which product line should be improved in each branch (based on the average quantity of all branches) 
WITH avg_data AS (
     SELECT AVG(quantity) AS overall_avg_quantity 
     FROM sales
)
SELECT product_line, AVG(quantity) AS avg_quantity, overall_avg_quantity, 
CASE  
   WHEN AVG(quantity) > overall_avg_quantity THEN "Higher"
   ELSE "Lower"
END AS quantity_status
FROM sales, avg_data
/*we also need to group the overall average since each line need to compare with it*/
GROUP BY product_line, overall_avg_quantity; 
-- food and beverages & fashion accessories are lower in purchased quantity compared to other product lines
-- strangly enough electronic accessories has the highest average quantity which is 5.7 

# 9.) Most common product line by gender
SELECT product_line, 
       gender, 
       COUNT(product_line) AS total_amt
FROM sales
GROUP BY product_line, gender
ORDER BY total_amt DESC;

# 10.) which branch sold more products than average product 
SELECT branch,  
       AVG(quantity) AS quantity_avg
FROM sales
GROUP BY branch
HAVING quantity_avg > (SELECT AVG(quantity) FROM sales);

-- but let's get all the information of each branch also
WITH avg_data AS (
     SELECT AVG(quantity) AS overall_avg_quantity 
     FROM sales
)
SELECT branch, AVG(quantity) AS avg_quantity , overall_avg_quantity, 
CASE 
   WHEN AVG(quantity) > overall_avg_quantity THEN "Higher"
   ELSE "Lower"
END AS quantity_status
FROM sales, avg_data
GROUP BY branch, overall_avg_quantity;

-- c is doing good while A, B are lower than the average.

# 11.) Revenue Contribution Percentage by Product Line (hard) 
SELECT sum(total)/(SELECT sum(total) FROM sales)*100 AS rev_percent, 
       product_line
FROM sales 
GROUP BY product_line
ORDER BY rev_percent DESC;
-- food and beverages has the highest percentage which is 17.38% followed by Sports and travel which is 17.06%

# 12.) customer distribution across the city 
SELECT city, 
       COUNT(customer_type) AS customers
FROM sales
GROUP BY city
ORDER BY customers DESC;
-- Yangon has the highest number of customers (340 people) which followed by Mandalay (332) and Naypyitaw (328).

# 13.) Most Profitable Payment Method
SELECT payment, 
       sum(total) AS total
FROM sales 
GROUP BY payment
ORDER BY total DESC;
-- Cash (112,206.57) is the most profitable payment method followed by EWALLET(109,993.107), and Credit Card (100,767.07)







