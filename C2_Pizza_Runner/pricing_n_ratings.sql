-- Pricing & Ratings
use pizza_runner;

-- Q.1) If a Meat Lovers pizza cost $12 and vegeterian pizza cost $10 and if there are no charges for change
-- How much pizza runner has made so far if there are no delivery charges?
select * from pizza_names;
SELECT co.pizza_id, pn.pizza_name,
SUM(
    case when pn.pizza_name = 'Meatlovers' Then 12 
    when pn.pizza_name = 'Vegetarian' Then 10
    Else 0 End
) AS pizza_cost
From customer_orders co
JOIN runner_orders ro
ON co.order_id = ro.order_id
JOIN pizza_names pn 
ON co.pizza_id = pn.pizza_id
Where ro.cancellation is NULL
Group By co.pizza_id, pn.pizza_name;

-- Q.2) What if there is an additional charge $1 for any pizza extras?
With cte_extra_charge AS (
SELECT co.order_id,co.pizza_id, pn.pizza_name,co.extras,
SUM(
    case when pn.pizza_name = 'Meatlovers' Then 12 
    when pn.pizza_name = 'Vegetarian' Then 10
    Else 0 End
) AS pizza_cost
From customer_orders AS co
Left JOIN runner_orders ro
ON co.order_id = ro.order_id
Left JOIN pizza_names pn 
ON co.pizza_id = pn.pizza_id
Where ro.cancellation is NULL
Group By co.pizza_id, pn.pizza_name,extras,co.order_id
),
cte_extra_split AS (
    Select 
        pizza_id,
        extras,
        order_id,
        1 AS extra_charge,
        value as extra
    From customer_orders
    Cross APPLY string_split(extras,',')
)
SELECT
s.pizza_id,SUM(pizza_total_cost) As pizza_total_cost
From 
(SELECT
    cec.pizza_id, pizza_cost, isnull(extra_charge,0) AS extra_charge,
    cec.extras,ces.extra,
    (pizza_cost + ISNULL(extra_charge,0)) AS pizza_total_cost
From cte_extra_charge cec 
Left Join cte_extra_split ces 
ON cec.pizza_id = ces.pizza_id
AND cec.order_id = ces.order_id
AND cec.extras = ces.extras) s
Group By s.pizza_id;

/* Q.3) The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
how would you design an additional table for this new dataset - generate a schema for this new table and 
insert your own data for ratings for each successful customer order between 1 to 5.*/

Drop Table If EXISTS pizza_runner.dbo.pizza_runner_ratings;
Create table pizza_runner.dbo.pizza_runner_ratings(
    id Int,
    runner_id int,
    order_id INT,
    customer_id int,
    rating_1_to_5 int,
    rating_time datetime
);

insert into pizza_runner.dbo.pizza_runner_ratings (id, order_id, customer_id, runner_id, rating_1_to_5, rating_time)
Values  ('1','1', '101', '1', '5', '2020-01-01 19:34:51'),
  ('2','2', '101', '1', '5', '2020-01-01 20:23:03'),
  ('3','3', '102', '1', '4', '2020-01-03 10:12:58'),
  ('4','4', '103', '2', '5', '2020-01-04 16:47:06'),
  ('5','5', '104', '3', '5', '2020-01-08 23:09:27'),
  ('6','7', '105', '2', '4', '2020-01-08 23:50:12'),
  ('7','8', '102', '2', '4', '2020-01-10 12:30:45'),
  ('8','10', '104', '1', '5', '2020-01-11 20:05:35'); 

  Select * From pizza_runner_ratings;

/* Q.4) Using your newly generated table - can you join all of the information together 
to form a table which has the following information for successful deliveries?
customer_id
order_id
runner_id
rating
order_time
pickup_time
Time between order and pickup
Delivery duration
Average speed
Total number of pizzas*/
select * from runner_orders;
SELECT
    co.customer_id,
    co.order_id,
    ro.runner_id,
    pr.rating_1_to_5 AS rating,
    co.order_time,
    ro.pickup_time,
    DATEDIFF(MINUTE,order_time,pickup_time) AS 'time bet order and pickup',
    ro.durations,
    Avg(60*(ro.distances / ro.durations)) AS 'average speed',
    COUNT(co.pizza_id) AS 'Total number of pizzas'    
From customer_orders co 
JOIN runner_orders ro 
ON co.order_id = ro.order_id
JOIN pizza_runner_ratings pr 
ON co.order_id = pr.order_id;
