create database Alt ;

use Alt ;

select * from customer_orders;
select * from payments;

select * from customer_orders  join payments  using (order_id) ;

SELECT VERSION();

CREATE VIEW Sales AS
SELECT *
FROM customer_orders
JOIN payments USING (order_id);
 
 Select count(*) from Sales;
 Select 
 Count(
 distinct order_id , customer_id, order_date, order_amount, shipping_address, order_status, payment_id, payment_date, payment_amount, payment_method, payment_status
 ) As Unique_Record from sales;
 
 /* 1. Order and Sales Analysis */
 
 -- a) Count of orders by status
SELECT order_status, COUNT(*) AS order_count
FROM Sales
GROUP BY order_status
ORDER BY order_count DESC;

-- b) Total sales revenue
SELECT SUM(order_amount) AS total_revenue
FROM Sales;

-- c) Average order value
SELECT AVG(order_amount) AS average_order_value
FROM Sales;

-- d) Monthly sales trend
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS sales_month,
    SUM(order_amount) AS monthly_revenue,
    COUNT(order_id) AS monthly_orders
FROM sales
GROUP BY sales_month
ORDER BY sales_month;

-- e) Order status distribution over time (monthly)
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS order_month,
    order_status,
    COUNT(*) AS order_count
FROM Sales
GROUP BY order_month, order_status
ORDER BY order_month, order_count DESC;


/* 2.Cutomer Analysis */

-- a) Count of orders per customer:  How many orders each customer has placed.
SELECT
    customer_id,
    COUNT(order_id) AS total_orders
FROM Sales
GROUP BY customer_id
ORDER BY total_orders DESC;

-- b) Identify repeat customers (customers with more than one order):  Filters for customers who've ordered more than once.
SELECT
    customer_id,
    COUNT(order_id) AS total_orders
FROM Sales
GROUP BY customer_id
HAVING COUNT(order_id) > 1
ORDER BY total_orders DESC;

-- c) Time between first and last order for repeat customers:  Calculates how long repeat customers take between their first and last orders.
WITH CustomerOrderDates AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date,
        MAX(order_date) AS last_order_date
    FROM sales
    GROUP BY customer_id
    HAVING COUNT(order_id) > 1
)
SELECT
    customer_id,
    first_order_date,
    last_order_date,
    DATEDIFF(last_order_date, first_order_date) AS days_between_orders
FROM CustomerOrderDates
ORDER BY days_between_orders DESC;

-- d) Customer ordering trends over time (e.g., first order month):  Shows when new customers started ordering.
SELECT
    sub.first_order_month,
    COUNT(DISTINCT sub.customer_id) AS new_customers
FROM (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS first_order_month,
        customer_id
    FROM Sales
) AS sub
GROUP BY sub.first_order_month
ORDER BY sub.first_order_month;  

/*3. Payments Status Analysis */

-- a) Count of payments by payment status:  How many payments are in each status (e.g., completed, failed).
SELECT
    payment_status,
    COUNT(payment_id) AS payment_count  -- Count payments
FROM Sales
GROUP BY payment_status
ORDER BY payment_count DESC;

-- b) Payment method distribution:  Which payment methods are used most often.
SELECT
    payment_method,
    COUNT(payment_id) AS payment_count
FROM Sales
GROUP BY payment_method
ORDER BY payment_count DESC;

-- c) Relationship between order status and payment status:  See how order and payment statuses relate.
SELECT
    order_status,
    payment_status,
    COUNT(payment_id) AS payment_count,
    COUNT(order_id) AS order_count  -- Count orders for each combination
FROM Sales
GROUP BY order_status, payment_status
ORDER BY order_status, payment_count DESC;

-- d) Potential issues: Orders with a fulfilled/completed status but failed payments:  Flags orders that might have problems.
SELECT
    order_id,
    order_status,
    payment_status
FROM Sales
WHERE order_status IN ('Shipped', 'Delivered', 'Completed')  -- Check these order statuses
    AND payment_status IN ('Failed', 'Rejected');  -- With these payment statuses
   
/* 5.Order Details Report */

-- Comprehensive order details report:  Selects all order and payment information.
SELECT
    order_id,
    customer_id,
    order_date,
    order_amount,
    shipping_address,
    order_status,
    payment_id,
    payment_date,
    payment_amount,
    payment_method,
    payment_status
FROM Sales
ORDER BY order_date DESC;  -- Order by date  

/* 5.Customer Retention Analysis */
--  This query prepares the data for a cohort analysis visualization.

WITH FirstOrderMonth AS (
    SELECT
        customer_id,
        DATE_FORMAT(MIN(order_date), '%Y-%m') AS first_order_month  -- MySQL date formatting
    FROM Sales
    GROUP BY customer_id
),
MonthlyOrders AS (
    SELECT
        customer_id,
        DATE_FORMAT(order_date, '%Y-%m') AS order_month  -- MySQL date formatting
    FROM Sales
),
CohortAnalysis AS (
    SELECT
        f.first_order_month,
        m.order_month,
        COUNT(DISTINCT f.customer_id) AS num_customers_in_cohort
    FROM FirstOrderMonth f
    JOIN MonthlyOrders m ON f.customer_id = m.customer_id
    GROUP BY f.first_order_month, m.order_month
)
SELECT
    first_order_month,
    order_month,
    num_customers_in_cohort,
    -- Calculate cohort month number using SIGNED integers
    (CAST(SUBSTR(order_month, 1, 4) AS SIGNED) - CAST(SUBSTR(first_order_month, 1, 4) AS SIGNED)) * 12 +
    (CAST(SUBSTR(order_month, 6, 2) AS SIGNED) - CAST(SUBSTR(first_order_month, 6, 2) AS SIGNED)) AS cohort_month_number
FROM CohortAnalysis
ORDER BY first_order_month, cohort_month_number;


