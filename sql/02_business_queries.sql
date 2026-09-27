-- 1. Total Revenue
SELECT
    ROUND(SUM(qty * price), 2) AS total_revenue
FROM analytics.order_items;


-- 2. Total Orders
SELECT
    COUNT(DISTINCT order_id) AS total_orders
FROM analytics.orders;

-- 3. Total Customers
SELECT
    COUNT(DISTINCT customer_id) AS total_customers
FROM analytics.orders;


-- 4. Average Order Value
SELECT
    ROUND(SUM(qty * price) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM analytics.order_items;


-- 5. Total Quantity Sold
SELECT
    SUM(qty) AS total_quantity_sold
FROM analytics.order_items;

-- 6. Total Refund Amount
SELECT
    ROUND(SUM(refund), 2) AS total_refund_amount
FROM analytics.returns;

-- 7. Return Rate
SELECT
    ROUND(
        COUNT(DISTINCT r.order_item_id)::NUMERIC
        / COUNT(DISTINCT oi.order_item_id) * 100,
        2
    ) AS return_rate_pct
FROM analytics.order_items oi
LEFT JOIN analytics.returns r
    ON oi.order_item_id = r.order_item_id;



-- 8. Average Revenue per Customer
SELECT
    ROUND(
        SUM(oi.qty * oi.price)
        / COUNT(DISTINCT o.customer_id),
        2
    ) AS avg_revenue_per_customer
FROM analytics.orders o
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id;


-- 9. Monthly Revenue Trend
SELECT
    DATE_TRUNC('month', o.order_date) AS month,
    ROUND(SUM(oi.qty * oi.price), 2) AS revenue
FROM analytics.orders o
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;


-- 10. Top 5 Customers by Revenue
SELECT
    o.customer_id,
    ROUND(SUM(oi.qty * oi.price), 2) AS revenue
FROM analytics.orders o
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id
GROUP BY o.customer_id
ORDER BY revenue DESC
LIMIT 5;


-- 11. Top Categories by Revenue
SELECT
    c.category_name,
    ROUND(SUM(oi.qty * oi.price), 2) AS revenue
FROM analytics.order_items oi
JOIN analytics.products p
    ON oi.product_id = p.product_id
JOIN analytics.categories c
    ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY revenue DESC;


-- 12. Top 5 Products by Revenue
SELECT
    oi.product_id,
    ROUND(SUM(oi.qty * oi.price), 2) AS revenue
FROM analytics.order_items oi
GROUP BY oi.product_id
ORDER BY revenue DESC
LIMIT 5;



-- 13. Most Returned Products
SELECT
    oi.product_id,
    COUNT(r.return_id) AS total_returns
FROM analytics.returns r
JOIN analytics.order_items oi
    ON r.order_item_id = oi.order_item_id
GROUP BY oi.product_id
ORDER BY total_returns DESC
LIMIT 10;



-- 14. Categories with Highest Returns
SELECT
    c.category_name,
    COUNT(r.return_id) AS total_returns
FROM analytics.returns r
JOIN analytics.order_items oi
    ON r.order_item_id = oi.order_item_id
JOIN analytics.products p
    ON oi.product_id = p.product_id
JOIN analytics.categories c
    ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY total_returns DESC;


-- 15. Highest Spending Customers
SELECT
    o.customer_id,
    ROUND(SUM(oi.qty * oi.price), 2) AS total_spend
FROM analytics.orders o
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id
GROUP BY o.customer_id
ORDER BY total_spend DESC
LIMIT 10;



-- 16. Revenue by Customer City
SELECT
    c.city,
    ROUND(SUM(oi.qty * oi.price), 2) AS revenue
FROM analytics.customers c
JOIN analytics.orders o
    ON c.customer_id = o.customer_id
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id
GROUP BY c.city
ORDER BY revenue DESC;


-- 17. Monthly Order Trend
SELECT
    DATE_TRUNC('month', order_date) AS month,
    COUNT(*) AS total_orders
FROM analytics.orders
GROUP BY month
ORDER BY month;


-- 18. Monthly Refund Trend
SELECT
    DATE_TRUNC('month', o.order_date) AS month,
    ROUND(SUM(r.refund), 2) AS refund_amount
FROM analytics.returns r
JOIN analytics.order_items oi
    ON r.order_item_id = oi.order_item_id
JOIN analytics.orders o
    ON oi.order_id = o.order_id
GROUP BY month
ORDER BY month;



-- Monthly Revenue Trend
SELECT
    DATE_TRUNC('month', o.order_date) AS month,
    ROUND(SUM(oi.qty * oi.price), 2) AS revenue
FROM analytics.orders o
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;


-- Step 21: Month-over-Month Revenue Change

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month,
        SUM(oi.qty * oi.price) AS revenue
    FROM analytics.orders o
    JOIN analytics.order_items oi
        ON o.order_id = oi.order_id
    GROUP BY month
)

SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        revenue - LAG(revenue) OVER (ORDER BY month),
        2
    ) AS revenue_change
FROM monthly_revenue
ORDER BY month;


-- Step 22: Biggest Monthly Revenue Decline

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month,
        SUM(oi.qty * oi.price) AS revenue
    FROM analytics.orders o
    JOIN analytics.order_items oi
        ON o.order_id = oi.order_id
    GROUP BY month
),

revenue_change AS (
    SELECT
        month,
        revenue,
        revenue - LAG(revenue) OVER (ORDER BY month) AS change_amount
    FROM monthly_revenue
)

SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(change_amount, 2) AS revenue_change
FROM revenue_change
WHERE change_amount IS NOT NULL
ORDER BY revenue_change ASC
LIMIT 1;


-- Step 23: Revenue by Category

SELECT
    c.category_name,
    ROUND(SUM(oi.qty * oi.price), 2) AS revenue
FROM analytics.order_items oi
JOIN analytics.products p
    ON oi.product_id = p.product_id
JOIN analytics.categories c
    ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY revenue DESC;



-- Step 24: Monthly Revenue by Category

SELECT
    DATE_TRUNC('month', o.order_date) AS month,
    c.category_name,
    ROUND(SUM(oi.qty * oi.price), 2) AS revenue
FROM analytics.orders o
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id
JOIN analytics.products p
    ON oi.product_id = p.product_id
JOIN analytics.categories c
    ON p.category_id = c.category_id
GROUP BY month, c.category_name
ORDER BY month, revenue DESC;



-- Step 25: Returns by Category

SELECT
    c.category_name,
    COUNT(r.return_id) AS total_returns
FROM analytics.returns r
JOIN analytics.order_items oi
    ON r.order_item_id = oi.order_item_id
JOIN analytics.products p
    ON oi.product_id = p.product_id
JOIN analytics.categories c
    ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY total_returns DESC;


-- Step 26: Refund Amount by Category

SELECT
    c.category_name,
    ROUND(SUM(r.refund), 2) AS refund_amount
FROM analytics.returns r
JOIN analytics.order_items oi
    ON r.order_item_id = oi.order_item_id
JOIN analytics.products p
    ON oi.product_id = p.product_id
JOIN analytics.categories c
    ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY refund_amount DESC;


-- Step 27: Monthly Payment Amount

SELECT
    DATE_TRUNC('month', o.order_date) AS month,
    ROUND(SUM(p.amount), 2) AS total_payment
FROM analytics.orders o
JOIN analytics.payments p
    ON o.order_id = p.order_id
GROUP BY month
ORDER BY month;


-- Step 28: Top Cities by Revenue

SELECT
    c.city,
    ROUND(SUM(oi.qty * oi.price), 2) AS revenue
FROM analytics.customers c
JOIN analytics.orders o
    ON c.customer_id = o.customer_id
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id
GROUP BY c.city
ORDER BY revenue DESC
LIMIT 10;


-- Step 29: Top Customers by Revenue

SELECT
    o.customer_id,
    ROUND(SUM(oi.qty * oi.price), 2) AS revenue
FROM analytics.orders o
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id
GROUP BY o.customer_id
ORDER BY revenue DESC
LIMIT 10;


-- Step 30: Top Products by Revenue

SELECT
    product_id,
    ROUND(SUM(qty * price), 2) AS revenue
FROM analytics.order_items
GROUP BY product_id
ORDER BY revenue DESC
LIMIT 10;


-- Step 31: Repeat Customers
SELECT
    customer_id,
    COUNT(*) AS total_orders
FROM analytics.orders
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY total_orders DESC
LIMIT 10;


-- Step 32: Products with Highest Return Count
SELECT
    oi.product_id,
    COUNT(r.return_id) AS total_returns
FROM analytics.order_items oi
JOIN analytics.returns r
    ON oi.order_item_id = r.order_item_id
GROUP BY oi.product_id
ORDER BY total_returns DESC
LIMIT 10;


-- Step 33: Monthly Revenue vs Refund
SELECT
    DATE_TRUNC('month', o.order_date) AS month,
    ROUND(SUM(oi.qty * oi.price), 2) AS revenue,
    ROUND(SUM(COALESCE(r.refund, 0)), 2) AS refund
FROM analytics.orders o
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id
LEFT JOIN analytics.returns r
    ON oi.order_item_id = r.order_item_id
GROUP BY month
ORDER BY month;