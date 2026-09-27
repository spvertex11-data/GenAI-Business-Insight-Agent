DROP TABLE IF EXISTS analytics.returns CASCADE;
DROP TABLE IF EXISTS analytics.payments CASCADE;
DROP TABLE IF EXISTS analytics.order_items CASCADE;
DROP TABLE IF EXISTS analytics.orders CASCADE;
DROP TABLE IF EXISTS analytics.products CASCADE;
DROP TABLE IF EXISTS analytics.categories CASCADE;
DROP TABLE IF EXISTS analytics.customers CASCADE;


SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'analytics';

CREATE TABLE analytics.customers (
    customer_id INTEGER PRIMARY KEY,
    city VARCHAR(100),
    signup_date DATE
);


CREATE TABLE analytics.categories (
    category_id INTEGER PRIMARY KEY,
    category_name VARCHAR(100)
);


CREATE TABLE analytics.products (
    product_id INTEGER PRIMARY KEY,
    category_id INTEGER,
    supplier_id INTEGER,
    price NUMERIC(12,2),
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id)
        REFERENCES analytics.categories(category_id)
);


CREATE TABLE analytics.orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    store_id INTEGER,
    order_date DATE,
    promotion_id INTEGER,
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES analytics.customers(customer_id)
);


CREATE TABLE analytics.order_items (
    order_item_id INTEGER PRIMARY KEY,
    order_id INTEGER,
    product_id INTEGER,
    qty INTEGER,
    price NUMERIC(12,2),
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES analytics.orders(order_id),
    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES analytics.products(product_id)
);

CREATE TABLE analytics.payments (
    payment_id INTEGER PRIMARY KEY,
    order_id INTEGER,
    amount NUMERIC(12,2),
    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id)
        REFERENCES analytics.orders(order_id)
);


CREATE TABLE analytics.returns (
    return_id INTEGER PRIMARY KEY,
    order_item_id INTEGER,
    refund NUMERIC(12,2),
    CONSTRAINT fk_returns_order_item
        FOREIGN KEY (order_item_id)
        REFERENCES analytics.order_items(order_item_id)
);


SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'analytics'
ORDER BY table_name;


SELECT COUNT(*)
FROM analytics.order_items;



SELECT 'categories' AS table_name, COUNT(*) AS row_count
FROM analytics.categories

UNION ALL

SELECT 'customers', COUNT(*)
FROM analytics.customers

UNION ALL

SELECT 'products', COUNT(*)
FROM analytics.products

UNION ALL

SELECT 'orders', COUNT(*)
FROM analytics.orders

UNION ALL

SELECT 'order_items', COUNT(*)
FROM analytics.order_items

UNION ALL

SELECT 'payments', COUNT(*)
FROM analytics.payments

UNION ALL

SELECT 'returns', COUNT(*)
FROM analytics.returns;



----Check duplicate primary keys
----Now we’ll validate that the important ID columns are unique.


SELECT
    'customers' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_ids
FROM analytics.customers

UNION ALL

SELECT
    'orders',
    COUNT(*),
    COUNT(DISTINCT order_id)
FROM analytics.orders

UNION ALL

SELECT
    'order_items',
    COUNT(*),
    COUNT(DISTINCT order_item_id)
FROM analytics.order_items

UNION ALL

SELECT
    'products',
    COUNT(*),
    COUNT(DISTINCT product_id)
FROM analytics.products

UNION ALL

SELECT
    'payments',
    COUNT(*),
    COUNT(DISTINCT payment_id)
FROM analytics.payments

UNION ALL

SELECT
    'returns',
    COUNT(*),
    COUNT(DISTINCT return_id)
FROM analytics.returns;


-- ============================================================
-- STEP 18A: CHECK NULL VALUES IN IMPORTANT COLUMNS
-- Purpose:
-- Make sure key business fields are not missing.
-- ============================================================

SELECT
    -- Count missing customer IDs
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,

    -- Count missing customer city values
    SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END) AS null_city,

    -- Count missing signup dates
    SUM(CASE WHEN signup_date IS NULL THEN 1 ELSE 0 END) AS null_signup_date
FROM analytics.customers;


-- ============================================================
-- STEP 18B: CHECK NULL VALUES IN ORDERS
-- ============================================================

SELECT
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS null_order_date
FROM analytics.orders;


-- ============================================================
-- STEP 18C: CHECK NULL VALUES IN ORDER ITEMS
-- ============================================================

SELECT
    SUM(CASE WHEN order_item_id IS NULL THEN 1 ELSE 0 END) AS null_order_item_id,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,
    SUM(CASE WHEN qty IS NULL THEN 1 ELSE 0 END) AS null_qty,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS null_price
FROM analytics.order_items;


-- ============================================================
-- STEP 18D: CHECK ORDERS WITHOUT A VALID CUSTOMER
-- Expected result: 0
-- ============================================================

SELECT COUNT(*) AS broken_customer_links
FROM analytics.orders o
LEFT JOIN analytics.customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- ============================================================
-- STEP 18E: CHECK ORDER ITEMS WITHOUT A VALID ORDER
-- Expected result: 0
-- ============================================================

SELECT COUNT(*) AS broken_order_links
FROM analytics.order_items oi
LEFT JOIN analytics.orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


-- ============================================================
-- STEP 18F: CHECK ORDER ITEMS WITHOUT A VALID PRODUCT
-- Expected result: 0
-- ============================================================

SELECT COUNT(*) AS broken_product_links
FROM analytics.order_items oi
LEFT JOIN analytics.products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


-- ============================================================
-- STEP 19: CORE BUSINESS KPIs
-- Purpose:
-- Create the main metrics that management would want to track.
-- These KPIs will also be useful later when Gemini answers
-- natural-language business questions.
-- ============================================================

SELECT
    -- Total revenue based on item-level sales
    ROUND(SUM(oi.qty * oi.price), 2) AS total_revenue,

    -- Total unique orders
    COUNT(DISTINCT o.order_id) AS total_orders,

    -- Total unique customers who placed orders
    COUNT(DISTINCT o.customer_id) AS total_customers,

    -- Average revenue generated per order
    ROUND(
        SUM(oi.qty * oi.price) / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS average_order_value,

    -- Total number of units sold
    SUM(oi.qty) AS total_quantity_sold,

    -- Total refund amount from returned items
    ROUND(
        COALESCE(
            (SELECT SUM(r.refund)
             FROM analytics.returns r),
            0
        ),
        2
    ) AS total_refund_amount,

    -- Percentage of order items that were returned
    ROUND(
        (
            SELECT COUNT(DISTINCT r.order_item_id)::NUMERIC
            FROM analytics.returns r
        )
        /
        NULLIF(COUNT(DISTINCT oi.order_item_id), 0)
        * 100,
        2
    ) AS return_rate_pct,

    -- Average revenue generated per customer
    ROUND(
        SUM(oi.qty * oi.price)
        / NULLIF(COUNT(DISTINCT o.customer_id), 0),
        2
    ) AS avg_revenue_per_customer

FROM analytics.orders o
JOIN analytics.order_items oi
    ON o.order_id = oi.order_id;



-- Step 19A: Total Revenue
SELECT
    ROUND(SUM(qty * price), 2) AS total_revenue
FROM analytics.order_items;



-- Step 19B: Total Orders
SELECT
    COUNT(DISTINCT order_id) AS total_orders
FROM analytics.orders;	



-- Step 19C: Total Customers
SELECT
    COUNT(DISTINCT customer_id) AS total_customers
FROM analytics.orders;


-- Step 19D: Average Order Value
SELECT
    ROUND(SUM(qty * price) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM analytics.order_items;


-- Step 19E: Total Quantity Sold
SELECT
    SUM(qty) AS total_quantity_sold
FROM analytics.order_items;


-- Step 19F: Total Refund Amount
SELECT
    ROUND(SUM(refund), 2) AS total_refund_amount
FROM analytics.returns;



-- Step 19G: Return Rate
SELECT
    ROUND(
        COUNT(DISTINCT r.order_item_id)::NUMERIC
        / COUNT(DISTINCT oi.order_item_id) * 100,
        2
    ) AS return_rate_pct
FROM analytics.order_items oi
LEFT JOIN analytics.returns r
    ON oi.order_item_id = r.order_item_id;


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
