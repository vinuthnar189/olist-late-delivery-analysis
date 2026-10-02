-- Olist late delivery analysis (SQLite)
-- Data: Brazilian E-Commerce Public Dataset by Olist (Kaggle, CC BY-NC-SA 4.0)
-- Tables used: olist_orders_dataset, olist_customers_dataset

-- 1. Data quality audit: count records that break each business rule
SELECT 'Total orders' AS check_name, COUNT(*) AS records FROM olist_orders_dataset
UNION ALL
SELECT 'Duplicate order_id', COUNT(*) - COUNT(DISTINCT order_id) FROM olist_orders_dataset
UNION ALL
SELECT 'Delivered but no delivery date', COUNT(*) FROM olist_orders_dataset
 WHERE order_status = 'delivered'
   AND (order_delivered_customer_date IS NULL OR order_delivered_customer_date = '')
UNION ALL
SELECT 'Delivered before purchase', COUNT(*) FROM olist_orders_dataset
 WHERE order_delivered_customer_date <> ''
   AND order_delivered_customer_date < order_purchase_timestamp
UNION ALL
SELECT 'Delivered before carrier pickup', COUNT(*) FROM olist_orders_dataset
 WHERE order_delivered_customer_date <> ''
   AND order_delivered_carrier_date <> ''
   AND order_delivered_customer_date < order_delivered_carrier_date
UNION ALL
SELECT 'Carrier pickup before purchase', COUNT(*) FROM olist_orders_dataset
 WHERE order_delivered_carrier_date <> ''
   AND order_delivered_carrier_date < order_purchase_timestamp
UNION ALL
SELECT 'Not delivered status but has delivery date', COUNT(*) FROM olist_orders_dataset
 WHERE order_status <> 'delivered'
   AND order_delivered_customer_date <> '';

-- 2. View that flags records with data quality issues
CREATE VIEW orders_dq AS
SELECT *,
 CASE
  WHEN (order_delivered_carrier_date <> '' AND order_delivered_carrier_date < order_purchase_timestamp) THEN 1
  WHEN (order_delivered_customer_date <> '' AND order_delivered_carrier_date <> '' AND order_delivered_customer_date < order_delivered_carrier_date) THEN 1
  WHEN (order_status <> 'delivered' AND order_delivered_customer_date <> '') THEN 1
  WHEN (order_status = 'delivered' AND (order_delivered_customer_date IS NULL OR order_delivered_customer_date = '')) THEN 1
  ELSE 0
 END AS dq_issue
FROM olist_orders_dataset;

-- 3. Late rate with and without the flagged records
-- "Late" = delivered after the estimated delivery date
SELECT 'All delivered orders' AS scope,
       COUNT(*) AS orders,
       SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) AS late_orders,
       ROUND(100.0 * SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) / COUNT(*), 2) AS late_pct
FROM orders_dq
WHERE order_status = 'delivered' AND order_delivered_customer_date <> ''
UNION ALL
SELECT 'Excluding flagged records',
       COUNT(*),
       SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) / COUNT(*), 2)
FROM orders_dq
WHERE order_status = 'delivered' AND order_delivered_customer_date <> '' AND dq_issue = 0;

-- 4. Late rate by customer state
-- Each order has its own customer_id in this dataset, so this join does not multiply rows
SELECT c.customer_state,
       COUNT(*) AS orders,
       SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS late_orders,
       ROUND(100.0 * SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) / COUNT(*), 2) AS late_pct
FROM orders_dq o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date <> '' AND o.dq_issue = 0
GROUP BY c.customer_state
ORDER BY late_pct DESC;

-- 5. Late rate by month
SELECT strftime('%Y-%m', order_purchase_timestamp) AS month,
       COUNT(*) AS orders,
       SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) AS late_orders,
       ROUND(100.0 * SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) / COUNT(*), 2) AS late_pct
FROM orders_dq
WHERE order_status = 'delivered' AND order_delivered_customer_date <> '' AND dq_issue = 0
GROUP BY month
ORDER BY month;

-- 6. Where does the time go? Days to carrier pickup vs days in transit
SELECT c.customer_state,
       COUNT(*) AS orders,
       ROUND(AVG(julianday(order_delivered_carrier_date) - julianday(order_purchase_timestamp)), 1) AS days_to_carrier,
       ROUND(AVG(julianday(order_delivered_customer_date) - julianday(order_delivered_carrier_date)), 1) AS days_in_transit
FROM orders_dq o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date <> ''
  AND o.order_delivered_carrier_date <> '' AND o.dq_issue = 0
  AND c.customer_state IN ('SP','RJ','BA','MG')
GROUP BY c.customer_state;

-- 7. Order-level extract used for the Excel pivot tables
SELECT o.order_id,
       c.customer_state AS state,
       strftime('%Y-%m', o.order_purchase_timestamp) AS month,
       CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END AS is_late,
       ROUND(julianday(o.order_delivered_carrier_date) - julianday(o.order_purchase_timestamp), 1) AS days_to_carrier,
       ROUND(julianday(o.order_delivered_customer_date) - julianday(o.order_delivered_carrier_date), 1) AS days_in_transit
FROM orders_dq o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date <> ''
  AND o.order_delivered_carrier_date <> '' AND o.dq_issue = 0;
