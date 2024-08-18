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
Left Join c1_dannys_dinner.dbo.sales AS ss
ON ppc.product_id = ss.product_id
Group by ppc.product_id, ppc.purchased_count,m.product_name,ss.customer_id;

-- Q5. Which item is the most popular for each customer.
Select inner_query.customer_id, inner_query.product_name, inner_query.product_count
From
(Select Count(s.product_id) As product_count, s.customer_id, m.product_name,
ROW_NUMBER() Over(partition by s.customer_id order by Count(s.product_id) desc) As rownum
From c1_dannys_dinner.dbo.sales As s 
Left Join c1_dannys_dinner.dbo.menu As m
On s.product_id = m.product_id
Group by s.customer_id, m.product_name) As inner_query  
Where inner_query.rownum = 1
Order by inner_query.customer_id;

-- Q6. Which item first purchased by customer after they became a member?

with most_popular AS (Select s.customer_id, me.join_date, m.product_name, s.order_date,
Row_Number() Over(
	Partition by s.customer_id
	Order by s.order_date asc
	) As rownum
From c1_dannys_dinner.dbo.sales AS s 
Inner Join c1_dannys_dinner.dbo.members AS me
ON s.customer_id = me.customer_id 
And s.order_date >= me.join_date
Inner Join c1_dannys_dinner.dbo.menu AS m
ON s.product_id = m.product_id
)

Select customer_id, rownum, product_name, order_date
From most_popular
Where rownum = 1;

-- Q7. Which item was purchased just before the customer became a member?
with purchased_before_member AS (
Select s.customer_id, m.product_name, s.order_date, me.join_date,
ROW_NUMBER() Over(
	Partition by s.customer_id
	Order by s.order_date desc
) As rownum
From c1_dannys_dinner.dbo.sales AS s
Inner Join c1_dannys_dinner.dbo.members AS me
ON s.customer_id = me.customer_id
AND s.order_date < me.join_date
Inner Join c1_dannys_dinner.dbo.menu AS m
ON s.product_id = m.product_id
)

Select
customer_id, order_date, product_name, join_date
From purchased_before_member
Where rownum = 1;

-- Q8. What is the total items and amount spent by each customer before the became a member?
Select s.customer_id, SUM(m.price) AS total_amount, COUNT(s.product_id) AS total_items
From c1_dannys_dinner.dbo.sales AS s
Left Join c1_dannys_dinner.dbo.members AS me
ON s.customer_id = me.customer_id
AND s.order_date >= me.join_date
Left Join c1_dannys_dinner.dbo.menu AS m
ON s.product_id = m.product_id
Where me.customer_id is null
Group by s.customer_id;

-- Q9. If each $1 spent equates to 10 points and sushi has 2x points multiplier -  how many points would each customer have?
with spent_points AS (Select 
s.customer_id, (CASE WHEN m.product_name = 'sushi' THEN m.price*20 else m.price*10 end) AS points
From c1_dannys_dinner.dbo.menu AS m
Join c1_dannys_dinner.dbo.sales AS s
ON s.product_id = m.product_id)

Select customer_id, SUM(points) AS points
From spent_points
Group by customer_id;

-- Q.10 In the first week after customer joins the program (including there join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B have at the end of January?
With points_by_monthend AS (Select s.customer_id, me.join_date, s.order_date, m.price, 
Datepart(week,s.order_date) AS order_date_week,
DATEPART(week,me.join_date) AS join_date_week,
DATEPART(month, s.order_date) AS order_date_month,
DATEPART(month, me.join_date) AS join_date_month,
DATENAME(m,s.order_date) As order_date_monthname,
DATENAME(m,me.join_date) As join_date_monthname
From c1_dannys_dinner.dbo.sales AS s
Join c1_dannys_dinner.dbo.members AS me
ON s.customer_id = me.customer_id
And s.order_date>=me.join_date
Join c1_dannys_dinner.dbo.menu AS m
ON s.product_id = m.product_id)

Select customer_id,order_date_monthname,join_date_monthname,order_date_month,join_date_month, 
	Sum(Case When order_date_week = join_date_week Then 2*price Else 1*price End) As points
From points_by_monthend
Group by customer_id,order_date_monthname,join_date_monthname,order_date_month,join_date_month
order by customer_id, order_date_month, join_date_month;