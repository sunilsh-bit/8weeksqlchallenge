Use SqlChallenge_8Week;

/*
Q.1) How would you calculate the rate of growth for Foodie-Fi?
To calculate growth rate, you can use the following formula:
Subtract the previous value from the current value
Divide the difference by the previous value
Multiply the result by 100 to get a percentage representation of the rate of growth 
*/

With Cust_2020 AS (
Select year(EOMONTH(start_date)) AS cy, count(customer_id) AS py_cust_count From c3_foodie_fi.subscriptions
Where EOMONTH(start_date) between '2020-01-01' AND '2020-04-30'
group by year(EOMONTH(start_date))
),
Cust_2021 AS (
Select year(EOMONTH(start_date)) AS cy, count(customer_id) AS cy_cust_count From c3_foodie_fi.subscriptions
Where EOMONTH(start_date) between '2021-01-01' AND '2021-04-30'
group by year(EOMONTH(start_date))
)
Select *, (py_cust_count - cy_cust_count) AS py_minus_cy,
(1.0*(py_cust_count - cy_cust_count) / py_cust_count)*100 AS growth_rate
From Cust_2020
cross join Cust_2021;

/* Q.2) What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?
--1. Churn Rate, Churn Count by month,
--2. Total Customers
--3. Growth Rate
--4. Customers joined the annual plan
--5. customer downgrade the plan
*/
With Churn_Count AS (
Select Year(EOMONTH(start_date)) AS churn_year, EOMONTH(start_date) start_date, customer_id
From c3_foodie_fi.subscriptions
Where plan_id = 4
),
Churn_Rate AS (
Select year(EOMONTH(s.start_date)) as years, count(distinct s.customer_id) as cust_count, count(distinct c.customer_id)churn_cust_count
From c3_foodie_fi.subscriptions s
join Churn_Count c
ON year(EOMONTH(s.start_date)) = churn_year
Group by year(EOMONTH(s.start_date)) 
),
Cust_2020 AS (
select year(start_date) as py, count(distinct customer_id) py_cust_count
from c3_foodie_fi.subscriptions
where year(start_date) = '2020'
group by year(start_date)
),
Cust_2021 AS (
Select year(start_date) as cy, count(distinct customer_id) cy_cust_count
from c3_foodie_fi.subscriptions
where year(start_date) = '2021'
group by year(start_date)
),
growth_rate AS (
select cy, py, cy_cust_count, py_cust_count, 
(1.0*(py_cust_count - cy_cust_count) / py_cust_count)*100 AS growth_rates, 
(py_cust_count - cy_cust_count)AS cust_increase_decrease
from Cust_2020 cross join Cust_2021
),
plan_cust AS (
Select plan_id, count(customer_id) as cust
From c3_foodie_fi.subscriptions
group by plan_id
),
downgrade_plan AS(
Select  a.customer_id,a.plan_id, a.lead_plan_id, (a.plan_id - a.lead_plan_id) AS Test
From
(Select
plan_id,customer_id,
lead(plan_id) Over(partition by customer_id Order by start_date) AS lead_plan_id
From c3_foodie_fi.subscriptions) a
Where (a.plan_id - a.lead_plan_id) >=1
)

Select years, cust_count AS total_customer, churn_cust_count AS churn_cust,
round((1.0*churn_cust_count / cust_count)*100,1) AS churn_rates, 
 cy, py, cy_cust_count, py_cust_count,growth_rates,cust_increase_decrease
From Churn_Rate
Join growth_rate ON years = cy;


/*
Q.3) What are some key customer journeys or experiences that you would analyse further to improve customer retention?
Q.4) If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?
Q.5) What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?*/

