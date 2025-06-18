"""
  Top queries for analysis ecommerce data
  using CTEs, WINDOW FUNCTION, Aggregation.....
"""


--- analysis
-- top 5 best selling product by revenue
SELECT
	p.product_id,
	p.product_name,
	ROUND(SUM(oi.quantity * oi.unit_price * (1- oi.discount / 100)),4) AS total_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC
LIMIT 5;

 -- Customer Lifetime Value (CLV) 
SELECT 
	c.customer_id,
	c.first_name || ' ' || c.last_name AS customer_name,
	ROUND(SUM(oi.subtotal + COALESCE(o.shipping_fee,0)),2) AS total_spent,
	COUNT(DISTINCT o.order_id) AS total_orders
FROM customer c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, customer_name
ORDER BY total_spent DESC
LIMIT 10;

-- category performance overview
SELECT 
	cat.category_name,
	COUNT(DISTINCT p.product_id) AS total_products,
	SUM(oi.quantity) AS total_units_sold,
	SUM(oi.subtotal) AS total_revenue
FROM categories cat
JOIN products p ON cat.category_id = p.category_id
JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY cat.category_name
ORDER BY total_revenue DESC;

--  Monthly Sales Trend 
SELECT 
	DATE_TRUNC('month',o.order_date) AS month,
	SUM(oi.subtotal + COALESCE(o.shipping_fee,0)) AS monthly_revenue,
	COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY month
ORDER BY month;

-- payment method distribution
SELECT
	payment_method,
	COUNT(*) AS total_orders,
	ROUND(SUM(oi.subtotal + COALESCE(o.shipping_fee, 0)), 2) AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY payment_method
ORDER BY total_revenue DESC;


-- cancelled order analysis
SELECT 
	c.country,
	COUNT(*) AS cancelled_orders
FROM orders o
JOIN customer c ON c.customer_id = c.customer_id
WHERE o.status = 'Cancelled'
GROUP BY c.country
ORDER BY cancelled_orders DESC;

 -- Product Stock Alerts
 SELECT 
 	product_id,
	product_name,
	stock_quantity
FROM products
WHERE is_active = TRUE AND stock_quantity < 5
ORDER BY stock_quantity ASC;

-- using cte 
-- Compute revenue and orders per customer, and then rank top customers
WITH customer_orders AS (
	SELECT 
	o.customer_id,
	COUNT(DISTINCT o.order_id) AS total_orders,
	SUM(oi.subtotal + COALESCE(o.shipping_fee,0)) AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY o.customer_id
)
SELECT
 	c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    co.total_orders,
    co.total_revenue,
    RANK() OVER (ORDER BY co.total_revenue DESC) AS revenue_rank
FROM customer_orders co
JOIN customer c ON c.customer_id = co.customer_id
ORDER BY revenue_rank
LIMIT 10;


 -- 30-day rolling revenue per day 
 SELECT 
 	o.order_date,
	SUM(oi.subtotal + COALESCE(o.shipping_fee,0)) OVER(
		ORDER BY o.order_date
		ROWS BETWEEN 20 PRECEDING AND CURRENT ROW
	)AS rolling_30d_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
ORDER BY o.order_date;

--Rank products by units sold within each category
WITH product_sales AS (
	SELECT 
		p.product_id,
		p.product_name,
		p.category_id,
		SUM(oi.quantity) AS total_units_sold
	FROM products p
	JOIN order_items oi ON oi.product_id = p.product_id
	GROUP BY p.product_id,p.product_name,p.category_id
)
SELECT 
	ps.*,
	DENSE_RANK() OVER(
		PARTITION BY ps.category_id
		ORDER BY ps.total_units_sold DESC
	) AS rank_within_category
FROM product_sales ps
ORDER BY ps.category_id, rank_within_category;

-- count active,inactive and zero-spending
SELECT
	CASE 
		WHEN total_spent>= 500 THEN 'High Value'
		WHEN total_spent BETWEEN 100 AND 499.99 THEN 'Mid Value'
		ELSE 'Low Value'
	END AS customer_segment,
	COUNT(*) AS customer_count
FROM (
	SELECT 
		o.customer_id,
		    SUM(oi.subtotal + COALESCE(o.shipping_fee, 0)) AS total_spent
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY o.customer_id
) t
GROUP BY customer_segment;

-- Monthly revenue with 3-month rolling average 
WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', o.order_date) AS month,
        SUM(oi.subtotal + COALESCE(o.shipping_fee, 0)) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT 
	month,
	revenue,
	ROUND(AVG(revenue) OVER(
		ORDER BY month
		ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),2
	)AS three_month_rolling_avg
FROM monthly_revenue
ORDER BY month;

-- Get the last 2 orders per customer (ROW_NUMBER)
WITH customer_order_ranked AS(
	SELECT o.order_id,
	o.customer_id,
	o.order_date,
	ROW_NUMBER() OVER(
		PARTITION BY o.customer_id
		ORDER BY o.order_date DESC
	)AS RN
	FROM orders o
	WHERE o.status = 'Completed'
)
SELECT * FROM customer_order_ranked
WHERE rn <= 2
ORDER BY customer_id, rn;
