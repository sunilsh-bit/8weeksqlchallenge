use c2_pizza_runner;

-- Q1. How many pizzas were ordered?
Select
COUNT(co_order_id) AS total_order
From c2_pizza_runner.dbo.dataset_joined;

-- Q2. How many unqiue customers order were made?
Select
COUNT(Distinct customer_id) As unique_customers, COUNT(co_order_id) AS total_order
From c2_pizza_runner.dbo.dataset_joined;

-- Q3. How many successful orders were delivered by each runner?
Select ro_runner_id,
COUNT(ro_order_id) AS successful_order_count
From c2_pizza_runner.dbo.dataset_joined
Where cancellation is null or cancellation = ''
Group by ro_runner_id;


-- Q4. How many each type of pizzas were delivered?
Select pn_pizza_name,COUNT(ro_order_id) AS delivered_count
From c2_pizza_runner.dbo.dataset_joined
Where distance!=0
Group by pn_pizza_name;

-- Q5. How many Vegeterian and Meatlover ordered by each customer?
Select customer_id, pn_pizza_name,
COUNT(ro_order_id) as orders
From c2_pizza_runner.dbo.dataset_joined
Group by pn_pizza_name,customer_id

-- Q6. What was the maximum number of pizzas delivered in a single order?
Select co_order_id, COUNT(co_pizza_id) AS pizzas_delivered
From c2_pizza_runner.dbo.dataset_joined
Where distance!=0
Group by co_order_id
Order by pizzas_delivered desc;

-- Q7.For each customer, how many delivered pizzas had at least 1 change and how many had no change?
select * from c2_pizza_runner.dbo.dataset_joined Order by co_order_id,customer_id;

	Select customer_id, 
	Sum(Case 
		When (trim(exclusions) != ' ' or trim(extras) != ' ')  THEN 1
		Else 0 End) AS at_least_1_change
	From c2_pizza_runner.dbo.dataset_joined
	Where distance!=0
	Group by customer_id
	Order by customer_id;
	
	Select customer_id, co_order_id,pn_pizza_id,
	Sum(Case 
		When (trim(exclusions) != ' ' or trim(extras) != ' ')  THEN 1
		Else 0 End) AS at_least_1_change,
	Sum(Case
		When (trim(exclusions) = ' ' AND TRIM(extras) = ' ') Then 1
		Else 0 End) As no_change
	From c2_pizza_runner.dbo.dataset_joined
	Where distance!=0
	Group by customer_id, co_order_id, pn_pizza_id
	Order by customer_id, co_order_id;

-- Q8. How many pizzas has been delivered that had both exclusions and extras?
Select co_pizza_id,pn_pizza_name,
Sum(Case when trim(exclusions) !=' ' And trim(extras) != ' ' Then 1 else 0 end) AS total_pizza_with_exclusions_n_extras
From c2_pizza_runner.dbo.dataset_joined
Where distance != 0
Group by co_pizza_id, pn_pizza_name;

-- Q9. What was the total volume of pizzas ordered for each hour of the day?
With order_date_dim AS (Select co_order_id,
Day(order_date) AS order_day, Month(order_date) AS order_month, Year(order_date) As order_year,
DATEPART(hour, order_date) AS order_hour
From c2_pizza_runner.dbo.dataset_joined)

Select COUNT(co_order_id) AS pizza_orders, order_hour
From order_date_dim
Group by order_hour
Order by order_hour;

-- Q10. What was the volume of orders for each day of the week?
With order_date_dim AS (Select co_order_id,
Day(order_date) AS order_day, Month(order_date) AS order_month, Year(order_date) As order_year,
DATEPART(hour, order_date) AS order_hour
From c2_pizza_runner.dbo.dataset_joined)

Select COUNT(co_order_id) AS pizza_ordered, order_day
From order_date_dim
Group by order_day
Order by order_day;