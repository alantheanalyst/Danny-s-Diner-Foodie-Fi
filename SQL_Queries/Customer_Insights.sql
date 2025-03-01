
--Amount Spent per Customer
SELECT customer_id, SUM(price) total_sales
FROM sales s JOIN menu m
ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY total_sales

-- Time Spent per Customer
SELECT customer_id, COUNT(DISTINCT order_date) total_visits
FROM sales
GROUP BY customer_id
ORDER BY total_visits

-- First item purchased by each customer
SELECT DISTINCT customer_id, order_date, product_name
FROM sales sales JOIN menu menu
ON sales.product_id = menu.product_id
WHERE order_date = '2021-01-01'
ORDER BY order_date 

-- Most popular item
SELECT top 1 product_name Most_Purchased_Meal, COUNT(product_name) Times_a_Meal_was_Purchased
FROM menu menu JOIN sales sales
ON menu.product_id = sales.product_id
GROUP BY product_name
ORDER BY Times_a_Meal_was_Purchased DESC

-- Times Customers Purchased Ramen.
SELECT customer_id, product_name, COUNT(product_name) ramen_count
FROM menu menu JOIN sales sales
ON menu.product_id = sales.product_id
WHERE product_name = 'Ramen'
GROUP BY customer_id, product_name

-- Most popular item per customer
SELECT DISTINCT customer_id, product_name, COUNT(sales.product_id) order_count
FROM sales sales JOIN menu menu
ON sales.product_id = menu.product_id
WHERE NOT customer_id = 'A' OR NOT sales.product_id IN (1, 2)
GROUP BY customer_id, product_name
ORDER BY customer_id, order_count DESC

-- First Item Purchased by Customers after becoming members
WITH member_sales AS (
SELECT s.customer_id, order_date, product_name,
DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date) rank
FROM sales s JOIN menu m
ON s.product_id = m.product_id JOIN members m2 
ON s.customer_id = m2.customer_id
WHERE order_date > join_date
)
SELECT customer_id, product_name
FROM member_sales
WHERE rank = 1

-- First items purchased by members before becoming members
WITH member_sales AS (
SELECT s.customer_id, product_name, order_date,
DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date DESC) rank
FROM sales s JOIN menu m
ON s.product_id = m.product_id JOIN members m2
ON s.customer_id = m2.customer_id
WHERE order_date < join_date
)
SELECT DISTINCT customer_id, product_name, order_date
FROM member_sales
WHERE rank = 1

-- Number of items purchased and amount spent by members before their membersips
WITH total_cte AS
(SELECT s.customer_id, JOIN_date, order_date, product_id
FROM sales s JOIN members m
ON s.customer_id = m.customer_id
WHERE order_date < JOIN_date)
SELECT customer_id, SUM(cte.product_id) total_items_purhcased, SUM(price) total_amount
FROM total_cte cte JOIN menu m
	on cte.product_id = m.product_id
GROUP BY cte.customer_id

-- Points earned per customer ($1.00 = 10 points & Sushi has 2x points mulitplyer)
SELECT customer_id,
SUM(
CASE
	WHEN sales.product_id in (2, 3) THEN (price * 10)
	ELSE (price * 20)
END) points
FROM sales sales JOIN menu menu
ON sales.product_id = menu.product_id
GROUP BY customer_id
ORDER BY points

-- Points earned per Customer if all items give 2x on the first week of membership
WITH cte as (
SELECT customer_id
, join_date
, DATEADD(DAY, 6, join_date) AS day_7
FROM members
)
SELECT a.customer_id, 
SUM(CASE
    WHEN product_name = 'sushi' THEN price * 20
    WHEN order_date BETWEEN join_date AND day_7 THEN price * 20
    ELSE price * 10 END) AS points
FROM sales a
JOIN cte 
 ON a.customer_id = cte.customer_id
JOIN menu c
 ON a.product_id = c.product_id
 where order_date <= '2021-01-31'
GROUP BY a.customer_id
