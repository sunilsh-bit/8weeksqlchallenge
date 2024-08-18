USE SqlChallenge_8Week;

-- Q.1) HOW MANY CUSTOMERS HAS FOODIE_FI EVER HAD?
SELECT COUNT(DISTINCT customer_id) AS CUSTOMERS
FROM c3_foodie_fi.subscriptions;

-- Q.2) WHAT IS A MONTHLY DISTRIBUTION OF TRIAL PLAN START_DATE VALUES FOR OUR DATASET USE FOR OUR DATASET 
-- USE THE START OF MONTH AS THE GROUP BY VALUE?

SELECT
DATEADD(DAY,1,EOMONTH(start_date,-1)) AS start_day_month,
COUNT(DISTINCT customer_id) AS CUSTOMERS
FROM c3_foodie_fi.subscriptions
WHERE plan_id = 0
GROUP BY DATEADD(DAY,1,EOMONTH(start_date,-1))
ORDER BY start_day_month;

-- Q.3) What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT EOMONTH(start_date) AS EOMONTH_start_date,
	COUNT(CASE WHEN plan_id = 0 THEN customer_id END) AS PLAN_0,
	COUNT(CASE WHEN plan_id = 1 THEN customer_id END) AS PLAN_1,
	COUNT(CASE WHEN plan_id = 2 THEN customer_id END) AS PLAN_2,
	COUNT(CASE WHEN plan_id = 3 THEN customer_id END) AS PLAN_3,
	COUNT(CASE WHEN plan_id = 4 THEN customer_id END) AS PLAN_4
FROM c3_foodie_fi.subscriptions
WHERE start_date > '2020-12-31'
GROUP BY EOMONTH(start_date);


/*
OR
Explanation
1. SELECT DISTINCT ',' + QUOTENAME(CONVERT(VARCHAR, StartDate, 120))
SELECT DISTINCT: This selects distinct values from the StartDate column in the #SampleData table.

CONVERT(VARCHAR, StartDate, 120): This converts the StartDate column to a VARCHAR string in the format 
YYYY-MM-DD HH:MI:SS (style 120). This format is used to ensure that the date is consistent and suitable for use as a column name.

QUOTENAME(...): This function adds square brackets [] around the StartDate string to make it a valid SQL identifier. 
This is necessary because column names in SQL cannot have spaces or special characters unless they are enclosed in brackets.

',' + QUOTENAME(...): The comma , is concatenated with each QUOTENAME result. 
This will help in creating a comma-separated list of column names.

2. FOR XML PATH('')
FOR XML PATH(''): This is a SQL Server feature that allows you to concatenate row values into a single string.
When you use FOR XML PATH(''), it generates XML but without any tags (because the path is set to an empty string '').

The result is a single concatenated string of all the distinct, comma-separated, and quoted StartDate values.

3. .value('.', 'NVARCHAR(MAX)')
.value('.', 'NVARCHAR(MAX)'): This extracts the concatenated string from the XML and converts it into a single NVARCHAR(MAX) string. 
The dot . refers to the current node in the XML (which in this case is the whole string).
4. STUFF(..., 1, 1, '')
STUFF(...): The STUFF function is used to delete a certain number of characters from a string 
and insert another string in their place.

STUFF(string, start, length, replaceWith):

string: The string to modify.
start: The position to start deleting characters.
length: The number of characters to delete.
replaceWith: The string to insert (in this case, it's an empty string '').
In this context, STUFF removes the first character (which is a comma ,), effectively cleaning up the string to 
create a list of comma-separated column names.

5. Result Stored in @cols
The final result, stored in the @cols variable, is a comma-separated string of distinct StartDate 
values formatted as SQL column names, which can be used in a PIVOT query.*/
DECLARE @cols AS NVARCHAR(MAX),
	@query AS NVARCHAR(MAX);

SET @cols = STUFF((SELECT DISTINCT ',' + QUOTENAME(CONVERT(varchar,eomonth(start_date),120))
	FROM c3_foodie_fi.subscriptions
	FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)'),1,1,'');


SET @query = '
	SELECT plan_id' + @cols + ' FROM ( SELECT plan_id, CONVERT(VARCHAR, eomonth(start_date), 120) AS start_date
	FROM c3_foodie_fi.subscriptions
	)x 
	PIVOT(
		COUNT(start_date)
		FOR start_date IN ('+@cols+')
	)p;';

exec sp_executesql @query;

/* Q.4) What is the customer count and percentage of customers who have churned rounded to 1 decimal place? */
With no_cust_by_plan AS (
Select p.plan_name, count(s.customer_id) AS customer From c3_foodie_fi.subscriptions s
Left Join c3_foodie_fi.plans p
ON s.plan_id = p.plan_id
Group By p.plan_name),
no_cust_by_churn AS (
	Select * From no_cust_by_plan Where plan_name = 'churn'
)
select sum(ncbp.customer) as customer, 
sum(ncbc.customer) as churn_count, round((1.0*sum(ncbc.customer) / sum(ncbp.customer))*100,1) as churn_percentage
from no_cust_by_plan ncbp 
left join no_cust_by_churn ncbc
on ncbp.plan_name = ncbc.plan_name;


-- Q.5) How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
with churn_cust AS (
select a.* 
from (select customer_id, plan_id, 
lag(plan_id) over(partition by customer_id order by start_date) as lag_plan_id
from c3_foodie_fi.subscriptions) As a
where 
(a.plan_id - a.lag_plan_id) = 4)
Select round((1.0*count(distinct c.customer_id) / count(distinct s.customer_id))*100,0) AS churn_percent,
count(c.customer_id) AS churn_cust_count
From c3_foodie_fi.subscriptions s 
left join churn_cust c 
on s.plan_id = c.plan_id AND
s.customer_id = c.customer_id;

-- Q.6) What is the number and percentage of customer plans after their initial free trial?
With plan_after_initial AS
(Select a.plan_id,a.lag_plan_id,count(a.customer_id) as customer From 
(select plan_id, customer_id, 
lag(plan_id) Over (partition by customer_id order by start_date) AS lag_plan_id
from c3_foodie_fi.subscriptions) a
Where a.lag_plan_id = 0
group by a.plan_id, a.lag_plan_id),
count_distinct_cust as(
select count(distinct customer_id) as distinct_cust
from c3_foodie_fi.subscriptions
)
select plan_id,
(1.0*avg(customer) / Avg(distinct_cust))*100 AS cust_percent 
from count_distinct_cust 
cross join plan_after_initial
group by plan_id;

-- Q.7) What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
with cust20_by_plan AS (
select plan_id, count(distinct customer_id) as cust_count, count(1) as cust
from c3_foodie_fi.subscriptions
where start_date <= '2020-12-31'
group by plan_id),
total_cust20 AS (
select count(distinct customer_id) as total_cust_count
from c3_foodie_fi.subscriptions
where start_date <= '2020-12-31'
)
select cp.*, tc.*, (1.0*cust_count / total_cust_count)*100 as plan_percent 
from cust20_by_plan cp
cross join total_cust20 tc;

-- Q.8) How many customers have upgraded to an annual plan in 2020?
select * from c3_foodie_fi.subscriptions where plan_id = 3 and start_date <= '2020-12-31';

-- Q.9) How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
 With min_max_start_date As (select customer_id, min(start_date) as min_start_date, max(start_date) max_start_date
 from c3_foodie_fi.subscriptions
 where customer_id IN (select customer_id from c3_foodie_fi.subscriptions where plan_id = 3)
 group by customer_id)
 
 select Avg(DATEDIFF(dd, min_start_date,max_start_date))as avg_days_to_annual_plan from min_max_start_date;

 -- Q.10) Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
 With min_max_start_date_period AS (
 Select customer_id, 
 MIN(start_date) AS min_start_date, 
 MAX(start_date) AS max_start_date, 
 DATEDIFF(dd,MIN(start_date),MAX(start_date)) AS days_to_annual_plan 
 From c3_foodie_fi.subscriptions 
 Where customer_id IN (select customer_id from c3_foodie_fi.subscriptions where plan_id= 3)
 group by customer_id),
 period_flag AS (
 Select days_to_annual_plan, 
 (case when days_to_annual_plan >= 0 and days_to_annual_plan <=30 Then '0-30 Days'
	 When days_to_annual_plan > 30 and days_to_annual_plan <= 60 Then '31-60 Days'
	 When days_to_annual_plan > 60 and days_to_annual_plan <=90 then '61-90 Days'
	 else 'More Than 90 Days'
	 End) AS period_flag
 From min_max_start_date_period)
 select avg(days_to_annual_plan) as avg_days_to_annual_plan, period_flag
 from period_flag
 group by period_flag;

 -- Q.11) How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
 With downgraded_cust AS (Select
 customer_id, plan_id,
 lead(plan_id) Over (partition by customer_id order by start_date) AS lead_plan_id,
 (plan_id - lead(plan_id) Over (partition by customer_id order by start_date)) AS new_plan_id
 From c3_foodie_fi.subscriptions
 Where start_date <= '2020-12-31')
 Select *
 From downgraded_cust
 Where plan_id = 2;