--Phare 1 Exploratory Analysis

--1. Total Revenue Generated
SELECT SUM(order_amount - discount) AS total_revenue
FROM orders;

--2. Total Orders Per City 
SELECT r.city, COUNT(o.order_id) AS total_orders
FROM orders o
JOIN restaurant r ON o.restaurant_id = r.restaurant_id
GROUP BY r.city
ORDER BY total_orders DESC;

--3. Top 10 Customers by Spending
SELECT c.name, SUM(o.order_amount - o.discount) AS total_spent
FROM orders o
JOIN customer c ON o.customer_id = c.customer_id
GROUP BY c.customer_id
ORDER BY total_spent DESC
LIMIT 10;

--PHASE 2 CUSTOMER SEGMENTATION 
--1. Customer Category (Gold/Silver/Bronze)
SELECT c.name,
       CASE 
           WHEN SUM(o.order_amount - o.discount) > 1000 THEN 'Gold'
           WHEN SUM(o.order_amount - o.discount)  BETWEEN 500 AND 1000 THEN 'Silver'
           ELSE 'Bronze'
       END AS customer_category
FROM orders o
JOIN customer c ON o.customer_id = c.customer_id
GROUP BY c.customer_id ,c.name ;

WITH customer_spending AS (
    SELECT c.customer_id,
           c.name,
           SUM(o.order_amount - o.discount) AS total_spent
    FROM orders o
    JOIN customer c ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, c.name
),
percentiles AS (
    SELECT customer_id,
           name,
           total_spent,
           NTILE(3) OVER (ORDER BY total_spent DESC) AS spending_group
    FROM customer_spending
)
SELECT customer_id,
       name,
       total_spent,
       CASE spending_group
           WHEN 1 THEN 'High-Value'
           WHEN 2 THEN 'Medium-Value'
           WHEN 3 THEN 'Low-Value'
       END AS customer_segment
FROM percentiles
ORDER BY total_spent DESC;

--PHASE 3 RESTAURANT PERFORMANCE 
--1.Top 10 Restaurants by Revenue
SELECT r.restaurant_name, r.restaurant_id,r.city,
    SUM(o.order_amount - o.discount) AS total_revenue
FROM orders o
JOIN restaurant r ON o.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_id, r.restaurant_name, r.city
ORDER BY total_revenue DESC
LIMIT 10;

--2. Average Rating vs Revenue
SELECT r.restaurant_name, r.rating, SUM(o.order_amount - o.discount) AS total_revenue
FROM orders o
JOIN restaurant r ON o.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_id, r.restaurant_name, r.rating
ORDER BY total_revenue DESC;

--PHASE 4 — DELIVERY ANALYSIS 
--1. Average Delivery Time Per City 
SELECT r.city, AVG(TIME_TO_SEC(o.delivery_time)) AS avg_delivery_time_seconds
FROM orders o
JOIN restaurant r ON o.restaurant_id = r.restaurant_id
GROUP BY r.city
ORDER BY avg_delivery_time_seconds ASC;

 --2.Late Deliveries (Above 45 Minutes)
SELECT o.order_id, r.city, o.delivery_time
FROM orders o
JOIN restaurant r ON o.restaurant_id = r.restaurant_id
WHERE (o.delivery_time) > 45
ORDER BY o.delivery_time DESC;

--PHASE 5 PAYMENT & DISCOUNT ANALYSIS 
--1.Payment Method Distribution
SELECT payment_method, COUNT(*) AS count
FROM orders
GROUP BY payment_method
ORDER BY count DESC;

--2. Discount Impact on Revenue
SELECT 
    CASE 
        WHEN discount > 0 THEN 'With Discount'
        ELSE 'Without Discount'
    END AS discount_status,
    SUM(order_amount - discount) AS total_revenue
FROM orders
GROUP BY discount_status;

--PHASE 6 ADVANCED SQL 
--1.Monthly Revenue Using CTE 
WITH monthly_revenue AS (
    SELECT 
        MONTH(order_date) AS month,
        SUM(order_amount - discount) AS revenue
    FROM orders
    GROUP BY month
)
SELECT month, revenue
FROM monthly_revenue
ORDER BY month;

-- 2.Rank Restaurants by Revenue (Window Function)
SELECT restaurant_name, total_revenue, RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM (
    SELECT r.restaurant_name, SUM(o.order_amount - o.discount) AS total_revenue
    FROM orders o
    JOIN restaurant r ON o.restaurant_id = r.restaurant_id
    GROUP BY r.restaurant_name
) AS restaurant_revenue;

-- 3.Above Average Revenue Restaurants (Subquery)
SELECT restaurant_name, total_revenue
FROM (  
    SELECT r.restaurant_name, SUM(o.order_amount - o.discount) AS total_revenue
    FROM orders o
    JOIN restaurant r ON o.restaurant_id = r.restaurant_id
    GROUP BY r.restaurant_name
) AS restaurant_revenue
WHERE total_revenue > (SELECT AVG(order_amount - discount) FROM orders);        

--PHASE 7 DATABASE OBJECTS 
--1.Create Revenue View 
CREATE VIEW revenue_view AS
SELECT 
    r.restaurant_name, r.city, r.restaurant_id, 
    SUM(o.order_amount - o.discount) AS total_revenue
FROM orders o
JOIN restaurant r ON o.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_name, r.city, r.restaurant_id;

--2.Stored Procedure: Get Top N Restaurants by Revenue
CREATE PROCEDURE GetTopRestaurantByRevenue(IN top_n INT)
BEGIN
    SELECT r.restaurant_id,
           r.restaurant_name,
           r.city,
           SUM(o.order_amount - o.discount) AS total_revenue
    FROM orders o
    JOIN restaurant r ON o.restaurant_id = r.restaurant_id
    GROUP BY r.restaurant_id, r.restaurant_name, r.city
    ORDER BY total_revenue DESC
    LIMIT top_n;
END;

CALL GetTopRestaurantByRevenue(10);

--PHASE 8 Performance Optimization 
--1.Index on order_date (for monthly reports)
CREATE INDEX idx_order_date ON orders(order_date);


--2.Index on customer_name (for joins)
CREATE INDEX idx_customer_name ON customer(name);

--3.Index on restaurant_name
CREATE INDEX idx_restaurant_name ON restaurant(restaurant_name);

--PHASE 9 —Automation Logic
-- High value orders
create table high_value_orders (
    log_id INT PRIMARY KEY auto_increment,
     order_id INT,
     customer_id INT,
     restaurant_id INT,
     order_amount DECIMAL(10,2),
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

--Example of trigger to log high value orders above 1000
CREATE TRIGGER trg_high_value_orders
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    IF NEW.order_amount > 1000 THEN
        INSERT INTO high_value_orders (order_id, customer_id, restaurant_id, order_amount)
        VALUES (NEW.order_id, NEW.customer_id, NEW.restaurant_id, NEW.order_amount);
    END IF;
END;

insert into food_app_project.orders values (1010, 231, 101, '2024-01-01', 1500.00, 100.00, 'Credit Card', '00:30:00');

--1. TRIGGER 1 — Prevent Negative Discount

CREATE TRIGGER prevent_negative_discount
BEFORE INSERT ON orders
FOR EACH ROW
BEGIN
    IF NEW.discount < 0 THEN
        SET NEW.discount = 0;
    END IF;
END;

insert into food_app_project.orders values (1011, 232, 102, '2024-01-02', 500.00, -50.00, 'Cash', '00:25:00');
select * from orders where order_id in (1010, 1011);

--2. Delivery Delay Warning
create table delivery_delay_log (
    log_id INT PRIMARY KEY auto_increment,
    order_id INT,
    customer_id INT,
    restaurant_id INT,
    delivery_time TIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
--TRIGGER 2 
CREATE TRIGGER log_late_delivery
AFTER insert ON orders
FOR EACH ROW
BEGIN
    IF NEW.delivery_time > 45 THEN
        INSERT INTO delivery_delay_log (order_id, customer_id, restaurant_id, delivery_time)
        VALUES (NEW.order_id, NEW.customer_id, NEW.restaurant_id, NEW.delivery_time);
    END IF;
END;

insert into food_app_project.orders values (1012, 231, 101, '2024-01-03', 300.00, 20.00, 'Mobile Payment', '00:50:00');
select * from delivery_delay_log where order_id = 1012;