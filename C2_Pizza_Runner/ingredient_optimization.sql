-- Ingredient Optimization
USE pizza_runner;

SELECT * FROM pizza_runner.dbo.pizza_recipes;

ALTER TABLE pizza_runner.dbo.pizza_recipes
ALTER Column toppings VARCHAR(50);

DROP TABLE IF EXISTS pizza_runner.dbo.pizza_recipes_optimized;

CREATE TABLE pizza_runner.dbo.pizza_recipes_optimized(
    pizza_id INT,
    toppings VARCHAR(50)
);

INSERT INTO pizza_runner.dbo.pizza_recipes_optimized(pizza_id, toppings)
SELECT
    pizza_id, 
    value AS toppings
FROM 
pizza_runner.dbo.pizza_recipes 
CROSS APPLY string_split(toppings,',');

CREATE VIEW pizza_ingredient AS 
SELECT po.*, pn.pizza_name, pt.topping_name FROM pizza_runner.dbo.pizza_recipes_optimized po
JOIN pizza_names pn
ON po.pizza_id = pn.pizza_id
JOIN pizza_toppings pt 
ON po.toppings = pt.topping_id;

-- Q.1) What are the standard ingredient for each pizza?
SELECT * FROM pizza_ingredient;

-- Q.2 & 3) What was the most commonly added extras and exclusions?
WITH cte_common_extras AS (
    SELECT pizza_id, 
    value AS extra 
    FROM customer_orders
    CROSS APPLY string_split(extras,',')
    WHERE extras IS NOT NULL
    GROUP BY pizza_id, value
),
cte_common_exclusions AS(
    SELECT pizza_id, 
    value AS exclusion
    FROM customer_orders
    CROSS APPLY string_split(exclusions,',')
    WHERE exclusions IS NOT NULL
    GROUP BY pizza_id, value
),
combined_extras_exclusions AS(
    SELECT *,'EXTRAS' AS SOURCE FROM cte_common_extras
    UNION ALL 
    SELECT *, 'EXCLUSIONS' AS SOURCE FROM cte_common_exclusions
)

SELECT ce.SOURCE,pto.topping_name, pn.pizza_name, ce.pizza_id, ce.extra AS extra_excl_value
FROM combined_extras_exclusions ce 
LEFT JOIN pizza_toppings pto
ON ce.extra = pto.topping_id
LEFT JOIN pizza_names pn 
ON ce.pizza_id = pn.pizza_id;  


select * from customer_orders;

/* Q.4) Generate an order item for each record in the customers_orders table in the format of one of the following:
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
*/

/* Algorithm -
1. apply the string_split on the whole dataset exclude exclusions
2. apply the string_split on the whole dataset exclude extras
3. join both cte's
4. concatenate the strings
5. apply the string_agg formula
*/
SELECT * FROM customer_orders;
WITH cte_extra_toppings AS (
    SELECT
        pizza_id,
        order_id,
        order_time,
        customer_id,
        value AS extra
    FROM pizza_runner.dbo.customer_orders
    CROSS APPLY string_split(extras,',')    
    GROUP BY 
        pizza_id,
        order_id,
        order_time,
        customer_id,
        value
),
cte_exclusion_toppings AS (
    SELECT 
        pizza_id,
        order_id,
        order_time,
        customer_id,
        value AS exclusion
    FROM customer_orders
    CROSS APPLY string_split(exclusions,',')
    GROUP BY 
        pizza_id,
        order_id,
        order_time,
        customer_id,
        value
),
cte_extra_joined AS (
    SELECT
        co.order_id,
        co.customer_id,
        coalesce(co.extras,'0') AS extras,
       -- co.exclusions,
        co.order_time,
        co.pizza_id,
        ce.extra
    FROM customer_orders co
    FULL OUTER JOIN cte_extra_toppings ce
    ON co.order_id = ce.order_id AND
    co.pizza_id = ce.pizza_id AND
    co.customer_id = ce.customer_id AND
    co.order_time = ce.order_time
  
),
cte_extra_final AS (
    SELECT s.* From
(select *,
    ROW_NUMBER() OVER 
    (partition by order_id, customer_id,pizza_id, order_time,extras 
    order by order_id, customer_id,pizza_id ) AS extra_row_number
 from cte_extra_joined) as s
Where s.extra_row_number = 1
-- order by s.order_id, s.customer_id,s.pizza_id
),
cte_exclusion_joined AS (
    SELECT
        co.order_id,
        co.customer_id,
        coalesce(co.exclusions,'0') AS exclusions,
       -- co.extras,
        co.order_time,
        co.pizza_id,
        cex.exclusion
    FROM customer_orders co
    FULL OUTER JOIN cte_exclusion_toppings cex
    ON co.order_id = cex.order_id AND
    co.pizza_id = cex.pizza_id AND
    co.customer_id = cex.customer_id AND
    co.order_time = cex.order_time
),
cte_exclusion_final AS (
    SELECT sa.* From
(select *,
    ROW_NUMBER() OVER 
    (partition by order_id, customer_id,pizza_id, order_time, exclusions 
    order by order_id, customer_id,pizza_id ) AS exclusion_row_number
 from cte_exclusion_joined) as sa
Where sa.exclusion_row_number = 1
-- order by sa.order_id, sa.customer_id,sa.pizza_id
),
cte_final AS (
    SELECT
         cor.order_id,
        cor.customer_id,
        cor.exclusions,
      cor.extras,
        cor.order_time,
        cor.pizza_id,
        cet.extra,
        cef.exclusion,
        ROW_NUMBER() OVER (partition by cor.order_id, cor.customer_id, cor.order_time,
        cor.pizza_id, cet.extra, cef.exclusion Order by cor.order_id, cor.customer_id, cor.order_time,
        cor.pizza_id ) AS row_num_filter
        FROM pizza_runner.dbo.customer_orders cor
    Join cte_exclusion_final cef 
    ON cor.order_id = cef.order_id AND
    cor.pizza_id = cef.pizza_id AND
    cor.customer_id = cef.customer_id AND
    cor.order_time = cef.order_time AND
    coalesce(cor.exclusions,'0') = cef.exclusions
    JOIN cte_extra_final cet 
    ON cor.order_id = cet.order_id AND
    cor.pizza_id = cet.pizza_id AND
    cor.customer_id = cet.customer_id AND
    cor.order_time = cet.order_time AND
    coalesce(cor.extras,'0') = cet.extras
)
SELECT sub.order_id,
string_agg((case when sub.exclusion_concat is null and sub.extra_concat is null then sub.pizza_name
     when sub.exclusion_concat is not null and sub.extra_concat is null then sub.exclusion_concat
     when sub.exclusion_concat is null and sub.extra_concat is not null then sub.extra_concat
     else concat(sub.exclusion_concat, ' ',sub.extra_concat) END),', ') AS concat_value
     FROM
(select cf.*, pn.pizza_name,
(case when exclusion is not null 
then concat(pn.pizza_name,' - Exclude ',ptex.topping_name) END) AS exclusion_concat,
(case when extra is not null 
then concat(pn.pizza_name,' - Extra ',pt.topping_name) END) AS extra_concat
 from cte_final cf
Join pizza_names pn on
cf.pizza_id = pn.pizza_id
Left join pizza_toppings pt on
cf.extra = pt.topping_id
Left join pizza_toppings ptex on
cf.exclusion = ptex.topping_id) AS sub
GROUP BY sub.order_id;


-- Q.6) What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
SELECT
    sub.extra,
    Cast(pt.topping_name AS Varchar(50)) As topping_names,
    COUNT(sub.extras) AS total_quantity
From (
SELECT 
    pizza_id,
    order_id,
    extras,
    value as extra
From customer_orders
Cross APPLY string_split(extras,',')
GROUP BY pizza_id,order_id,extras,value) AS sub
JOIN pizza_toppings pt ON
sub.extra = pt.topping_id
GROUP BY sub.extra,Cast(pt.topping_name AS Varchar(50))
order by total_quantity DESC;