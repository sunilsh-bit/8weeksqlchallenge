-- Q1. What is the total amount each customer spent at the restaurant?
use c1_dannys_dinner;

Select SUM(Price) as total_amount, s.customer_id
From c1_dannys_dinner.dbo.menu AS m
Join c1_dannys_dinner.dbo.sales AS s
ON m.product_id = s.product_id
Group by s.customer_id
Order by total_amount desc;

-- Q2. How many days has each customer visited the restaurant?
Select COUNT(product_id) as total_visited, customer_id
From c1_dannys_dinner.dbo.sales
Group by customer_id
order by total_visited desc;

-- Q3. What was the first item from the menu purchased by each customer?
Select pm.*, m.product_name
From (Select *,
ROW_NUMBER() Over(Partition by customer_id Order by order_date) As purchased_order
From c1_dannys_dinner.dbo.sales) as pm
Left Join c1_dannys_dinner.dbo.menu as m
On pm.product_id = m.product_id
Where purchased_order = 1;

-- Q4. What is the most purchased item from the menu and how many times it was purchased by each customer.

Select ppc.product_id, ppc.purchased_count,m.product_name,ss.customer_id, COUNT(ppc.product_id) AS purchased_no_times 
From
(Select s.product_id, COUNT(s.product_id) As purchased_count
From c1_dannys_dinner.dbo.sales AS s
Group by s.product_id
Having COUNT(s.product_id) = (Select Max(product_count) AS most_purchased_item
From (Select product_id, Count(product_id) AS product_count
From c1_dannys_dinner.dbo.sales
Group by product_id)As product_counts)
) AS ppc
Left Join c1_dannys_dinner.dbo.menu AS m
ON ppc.product_id = m.product_id
Left Join c1_dannys_dinner.dbo.sales as ss
ON ppc.product_id = ss.product_id
Group by ppc.product_id, ppc.purchased_count,m.product_name,ss.customer_id