-- Runners & Customer Experience

use pizza_runner;

-- Q.1) How many RUNNERS signed up for each 1 week period? (i.e. week starts 2021-01-01)
SET Datefirst 5;
SELECT COUNT(runner_id) AS runners,DATEPART(WEEK, registration_date) AS registered_week,
MIN(registration_date) AS min_date, MAX(registration_date) AS max_date
FROM pizza_runner.DBO.runner
GROUP BY DATEPART(WEEK, registration_date);

-- Q.2) What was the avg time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT ro.runner_id, Avg(DATEDIFF(MINUTE, co.order_time, ro.pickup_time)) AS Avg_Pickup_Time
FROM pizza_runner.DBO.runner_orders ro 
JOIN pizza_runner.DBO.customer_orders co 
ON ro.order_id = co.order_id
WHERE ro.cancellation is NULL
GROUP BY ro.runner_id;


-- Q.3) Is there any relationship between the number of pizzas and how long order takes to prepare?
WITH prep_time AS (
    SELECT
    COUNT(co.pizza_id) AS pizza_order,
    co.order_time,
    ro.pickup_time,
    ro.runner_id,
    co.order_id,
    co.customer_id
    FROM pizza_runner.dbo.customer_orders co 
    JOIN pizza_runner.dbo.runner_orders ro 
    ON co.order_id = ro.order_id
    WHERE ro.cancellation IS NULL 
    GROUP BY co.order_time,
    ro.pickup_time,
    ro.runner_id,
    co.order_id,
    co.customer_id
)

SELECT
    pizza_order,
    Avg(DATEDIFF(MINUTE, order_time, pickup_time)) AS avg_prep_time
FROM prep_time
GROUP BY pizza_order;

-- Q.4) What was the avg distance travelled for each customer?
WITH cte_avg_distnace AS (
    SELECT
        co.customer_id,
        Cast(ro.distances AS float) AS distances
    FROM pizza_runner.dbo.customer_orders co 
    JOIN pizza_runner.dbo.runner_orders ro 
    ON co.order_id = ro.order_id
    WHERE ro.cancellation IS NULL
)

SELECT
    customer_id,
    round(AVG(distances),1) AS distances
FROM cte_avg_distnace
GROUP BY customer_id
ORDER BY customer_id;

ALTER TABLE pizza_runner.dbo.runner_orders
ALTER COLUMN durations INT;
-- Q.5) What was the difference between the longest and shortes deliverey time?
WITH cte_long_short_delivery_time AS (
    SELECT
        Count(pizza_id) AS pizzas_ordered,
        CAST(ro.distances AS float) AS distances,
        durations,
        runner_id,
        pickup_time,
        DATEADD(MINUTE,CAST(durations AS Int),pickup_time) AS delivery_time
    FROM pizza_runner.DBO.customer_orders co 
    JOIN pizza_runner.dbo.runner_orders ro 
    ON co.order_id = ro.order_id
    WHERE ro.cancellation IS NULL 
    GROUP BY CAST(ro.distances AS float), durations, runner_id,pickup_time,
    DATEADD(MINUTE,CAST(durations AS Int),pickup_time)
)

SELECT 
    
    MIN(durations) AS min_delivery,
    Max(durations) AS max_delivery,
    AVG(distances) AS avg_distance
From cte_long_short_delivery_time;

ALTER TABLE pizza_runner.DBO.runner_orders
ALTER COLUMN distances FLOAT;

-- Q.6) What was the average speed for each runner for each delivery and do you notice any trends of these values?
-- Speed = distance / time;

WITH cte_runner_speed AS (
    SELECT
        pizza_id,
        distances,
        durations,
        runner_id,
        customer_id,
        ro.order_id,
        speed = distances / durations,
        order_time,
        pickup_time
    FROM pizza_runner.DBO.customer_orders co 
    JOIN pizza_runner.dbo.runner_orders ro 
    ON co.order_id = ro.order_id
    WHERE ro.cancellation IS NULL 
)

SELECT
    runner_id,
    customer_id,
    order_id,
    COUNT(pizza_id) AS pizzas_ordered,
    Avg(DATEDIFF(MINUTE, order_time, pickup_time)) AS avg_prep_time,
    AVG(speed*60) AS avg_speed,
    AVG(distances) AS avg_distances,
    AVG(durations) AS avg_durations
    
    FROM cte_runner_speed
GROUP BY runner_id, customer_id, order_id
Order by runner_id, customer_id, order_id;

-- Q.7) What is the successful delivery percentage for each runner?
SELECT
    runner_id,
    (SUM(100*
        CASE WHEN cancellation IS NULL  THEN 1 ELSE 0 END        
    ) / COUNT(*)) AS delivery_percentage
FROM pizza_runner.dbo.runner_orders
GROUP BY runner_id;