-- Superstore sales analysis
-- MySQL 8.0+ | Source table: superstore.order_file2
-- Run after importing the source dataset. The table is expected to contain
-- order_id, order_date, customer_name, product_id, category, sub_category,
-- region, country, sales, profit, quantity, and discount.
-- Each row is treated as an order line. In this extract, some order_id values
-- also occur with a different date/customer. An order is identified by the
-- combination (order_id, order_date, customer_name).

USE superstore;

-- 1. Overall sales and profit
SELECT ROUND(SUM(sales), 2) AS total_sales,
       ROUND(SUM(profit), 2) AS total_profit,
       COUNT(DISTINCT order_id, order_date, customer_name) AS distinct_orders,
       SUM(quantity) AS units_sold
FROM order_file2;

-- 2. Five products with the highest sales
SELECT product_id, ROUND(SUM(sales), 2) AS total_sales
FROM order_file2
GROUP BY product_id
ORDER BY total_sales DESC, product_id
LIMIT 5;

-- 3. Regions ranked by total profit
SELECT region, ROUND(SUM(profit), 2) AS total_profit
FROM order_file2
GROUP BY region
ORDER BY total_profit DESC, region;

-- 4. Monthly sales in chronological order
SELECT DATE_FORMAT(order_date, '%Y-%m') AS sales_month,
       ROUND(SUM(sales), 2) AS monthly_sales,
       COUNT(DISTINCT order_id, order_date, customer_name) AS distinct_orders
FROM order_file2
WHERE order_date IS NOT NULL
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY sales_month;

-- 5. Order lines that made a loss
SELECT order_id, order_date, product_id, sales, profit, discount
FROM order_file2
WHERE profit < 0
ORDER BY profit ASC, order_id;

-- 6. Customers ranked by total sales
-- Customer names are used because the supplied SQL does not establish a customer_id field.
SELECT customer_name, ROUND(SUM(sales), 2) AS total_sales,
       COUNT(DISTINCT order_id, order_date, customer_name) AS distinct_orders
FROM order_file2
WHERE customer_name IS NOT NULL
GROUP BY customer_name
ORDER BY total_sales DESC, customer_name
LIMIT 10;

-- 7. Sales, profit, and profit margin by category
SELECT category,
       ROUND(SUM(sales), 2) AS total_sales,
       ROUND(SUM(profit), 2) AS total_profit,
       ROUND(100 * SUM(profit) / NULLIF(SUM(sales), 0), 2) AS profit_margin_pct
FROM order_file2
GROUP BY category
ORDER BY total_sales DESC, category;

-- 8. Discount levels and profitability of order lines
-- This is descriptive; it does not establish that a discount caused a loss.
SELECT discount,
       COUNT(*) AS order_lines,
       ROUND(AVG(profit), 2) AS avg_profit_per_line,
       ROUND(SUM(profit), 2) AS total_profit
FROM order_file2
GROUP BY discount
ORDER BY discount;

-- 9. Products with the highest quantity sold
SELECT product_id, SUM(quantity) AS units_sold
FROM order_file2
GROUP BY product_id
ORDER BY units_sold DESC, product_id
LIMIT 5;

-- 10. Country ranking by sales
SELECT country,
       ROUND(SUM(sales), 2) AS total_sales,
       RANK() OVER (ORDER BY SUM(sales) DESC) AS sales_rank
FROM order_file2
GROUP BY country
ORDER BY sales_rank, country;

-- 11. Top three products by sales within each category
-- DENSE_RANK includes tied products; a category may return more than three rows.
WITH product_sales AS (
    SELECT category, product_id, SUM(sales) AS total_sales
    FROM order_file2
    GROUP BY category, product_id
), ranked AS (
    SELECT category, product_id, total_sales,
           DENSE_RANK() OVER (PARTITION BY category ORDER BY total_sales DESC) AS product_rank
    FROM product_sales
)
SELECT category, product_id, ROUND(total_sales, 2) AS total_sales, product_rank
FROM ranked
WHERE product_rank <= 3
ORDER BY category, product_rank, product_id;

-- 12. Running sales total by day
WITH daily_sales AS (
    SELECT DATE(order_date) AS order_day, SUM(sales) AS sales_on_day
    FROM order_file2
    WHERE order_date IS NOT NULL
    GROUP BY DATE(order_date)
)
SELECT order_day, ROUND(sales_on_day, 2) AS daily_sales,
       ROUND(SUM(sales_on_day) OVER (ORDER BY order_day), 2) AS running_sales
FROM daily_sales
ORDER BY order_day;

-- 13. First observed versus subsequent orders by month
-- These are first orders *in this dataset*, not necessarily first-ever purchases.
WITH orders AS (
    SELECT customer_name, order_id, order_date
    FROM order_file2
    WHERE customer_name IS NOT NULL AND order_id IS NOT NULL AND order_date IS NOT NULL
    GROUP BY customer_name, order_id, order_date
), sequenced AS (
    SELECT customer_name, order_id, order_date,
           ROW_NUMBER() OVER (
               PARTITION BY customer_name ORDER BY order_date, order_id
           ) AS customer_order_number
    FROM orders
)
SELECT DATE_FORMAT(order_date, '%Y-%m') AS order_month,
       SUM(CASE WHEN customer_order_number = 1 THEN 1 ELSE 0 END) AS first_observed_orders,
       SUM(CASE WHEN customer_order_number > 1 THEN 1 ELSE 0 END) AS subsequent_orders
FROM sequenced
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY order_month;

-- 14. Most profitable subcategory in each region
-- DENSE_RANK includes ties for first place.
WITH regional_profit AS (
    SELECT region, sub_category, SUM(profit) AS total_profit
    FROM order_file2
    GROUP BY region, sub_category
), ranked AS (
    SELECT region, sub_category, total_profit,
           DENSE_RANK() OVER (PARTITION BY region ORDER BY total_profit DESC) AS profit_rank
    FROM regional_profit
)
SELECT region, sub_category, ROUND(total_profit, 2) AS total_profit
FROM ranked
WHERE profit_rank = 1
ORDER BY region, sub_category;
