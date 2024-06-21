use c2_pizza_runner;
drop view if exists dataset_joined; 
Create View dataset_joined AS (
	Select 
	co.order_id as co_order_id, 
	co.customer_id as customer_id,
	co.pizza_id as co_pizza_id, 
	co.exclusions as exclusions, 
	co.extras as extras,
	co.order_time as order_date, 
	-- ro.order_id as order_id, 
	-- ro.runner_id as runner_id,
	ro.order_id as ro_order_id, 
	ro.runner_id as ro_runner_id, 
	ro.pickup_time as pickup_time, 
	ro.distances as distance,
	ro.durations as duration, 
	ro.cancellation as cancellation, 
	r.runner_id as r_runner_id, 
	r.registration_date,
	pn.pizza_id as pn_pizza_id,
	pn.pizza_names as pn_pizza_name,
	pr.pizza_id as pr_pizza_id,
	pr.toppings as pr_toppings
	From c2_pizza_runner.dbo.customer_orders AS co
	Left Join c2_pizza_runner.dbo.runner_orders AS ro
	ON co.order_id = ro.order_id
	Left join c2_pizza_runner.dbo.runners AS r
	ON ro.runner_id = r.runner_id
	Left Join c2_pizza_runner.dbo.pizza_names AS pn
	ON co.pizza_id = pn.pizza_id
	Left Join c2_pizza_runner.dbo.pizza_recipes AS pr
	ON co.pizza_id = pr.pizza_id);