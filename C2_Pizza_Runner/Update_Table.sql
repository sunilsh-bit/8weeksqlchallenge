use c2_pizza_runner;

Select * From c2_pizza_runner.dbo.customer_orders;

Update c2_pizza_runner.dbo.customer_orders
SET extras = NULL
Where extras = 'null';

Select * From c2_pizza_runner.dbo.customer_orders;

Select * From c2_pizza_runner.dbo.runner_orders;
Update c2_pizza_runner.dbo.runner_orders
SET pickup_time = TRY_CAST(pickup_time as datetime);
Select * From c2_pizza_runner.dbo.runner_orders;

Alter table c2_pizza_runner.dbo.runner_orders
Add distances float;

Alter table c2_pizza_runner.dbo.runner_orders
Add durations float;

Alter table c2_pizza_runner.dbo.pizza_names
Add pizza_names varchar(50);

Update c2_pizza_runner.dbo.runner_orders
SET distances = CAST(PARSE(LTRIM(RTRIM(REPLACE(REPLACE(distance,'km',''),'KM',''))) AS FLOAT)AS FLOAT), 
durations = CAST(Ltrim(Rtrim(Replace(Replace(Replace(duration,'minutes',''),'mins',''),'minute',''))) AS Float),
cancellation = (case when cancellation = 'null' then NULL else cancellation end);
Select * From c2_pizza_runner.dbo.runner_orders;

Update c2_pizza_runner.dbo.pizza_names
SET pizza_names = CAST(pizza_name AS varchar(50));

Alter Table c2_pizza_runner.dbo.pizza_names
Drop column pizza_name;