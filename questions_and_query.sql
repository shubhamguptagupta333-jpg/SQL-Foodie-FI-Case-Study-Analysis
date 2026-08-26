-- 1.  How many customers has Foodie-Fi ever had? 

select count(distinct customer_id) as total_customers
from subscriptions;

-- 2. What is the monthly distribution of trial plan start_date values for our dataset? — Use the start of the month as the group by value

select extract(month from s.start_date) as months,count(*) as cnt_plans
from plans as p
join subscriptions as s
on p.plan_id = s.plan_id
where plan_name = 'trial'
group by extract(month from s.start_date)
order by months;

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name.

select p.plan_name,count(*) as Event_count
from plans as p
join subscriptions as s
on p.plan_id = s.plan_id
where s.start_date > '2020-12-31'
group by p.plan_name;

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

with customer_count as 
(select count(distinct s.customer_id) as churn_customers
from plans as p
join subscriptions as s
on p.plan_id = s.plan_id
where p.plan_name = 'churn'), 

total_customers_count as 
(select count(distinct customer_id) as total_customers
from subscriptions)

select CC.churn_customers,round((CC.churn_customers*100)/TC.total_customers,1) as Churn_Percentage
from  customer_count as CC 
cross join total_customers_count as TC;

 -- 5.How many customers have churned straight after their initial free trial? 
 -- — what percentage is this rounded to the nearest whole number?
 
 
with Customer_Plans as 
(select customer_id,plan_id,lead(plan_id,1) over (partition by customer_id order by start_date) as next_plan
from subscriptions),
total_customers_count as 
(select count(distinct customer_id) as total_customers
from subscriptions)

select count(*) as customers_churned_after_freetrial,Round((count(*)*100)/TC.total_customers,0) as percentage
from Customer_Plans as CP
cross join total_customers_count as TC
where CP.plan_id= 0
and CP.next_plan = 4
group by TC.total_customers;


-- 6.  What is the number and percentage of customer plans after their initial free trial? 
 
  with Customer_Plans as 
(select customer_id,plan_id,lead(plan_id,1) over (partition by customer_id order by start_date) as next_plan
from subscriptions),
total_customers_count as 
(select count(distinct customer_id) as total_customers
from subscriptions)

select P.plan_name,count(*) as Customer_count,Round((count(*)*100)/TC.total_customers,1) as percentage
from Customer_Plans as CP
join plans as P
on CP.next_plan=P.plan_id
cross join total_customers_count as TC
where CP.plan_id=0
group by P.plan_name,TC.total_customers
order by Customer_count desc;


-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020–12–31? 

with Latest_Plan as 
(select customer_id,plan_id,row_number()over(partition by customer_id order by start_date desc) as seq
from subscriptions 
where start_date <= '2020-12-31'),

total_customers_count as 
(select count(distinct customer_id) as total_customers
from subscriptions)

select P.plan_name,count(*) as Customer_count,Round((count(*)*100)/TC.total_customers,1) as percentage
from Latest_Plan as LP
join plans as P 
on LP.plan_id=P.plan_id
cross join total_customers_count as TC
where seq=1
group by P.plan_name,TC.total_customers;


-- 8. How many customers have upgraded to an annual plan in 2020? 

select count(distinct customer_id) as annual_customers
from subscriptions
where plan_id = 3
and start_date >= '2020-01-01'
and start_date < '2021-01-01';


-- 9.  How many days on average does it take a customer to an annual plan from the day they join Foodie-Fi? 

select round(avg(datediff(a.start_date, t.start_date)), 0) as avg_days
from subscriptions t
join subscriptions a
on t.customer_id = a.customer_id
where t.plan_id = 0
and a.plan_id = 3;


-- 10.  Can you further breakdown this average value into 30-day periods? (i.e. 0–30 days, 31–60 days etc) 

with customer_dates as (
    select
        customer_id,
        min(case when plan_id = 0 then start_date end) as join_date,
        min(case when plan_id = 3 then start_date end) as annual_date
    from subscriptions
    group by customer_id
),
days_taken as (
    select
        customer_id,
        datediff(annual_date, join_date) as days_to_annual
    from customer_dates
    where annual_date is not null
)

select
    case
        when days_to_annual between 0 and 30 then '0-30 days'
        when days_to_annual between 31 and 60 then '31-60 days'
        when days_to_annual between 61 and 90 then '61-90 days'
        when days_to_annual between 91 and 120 then '91-120 days'
        when days_to_annual between 121 and 150 then '121-150 days'
        when days_to_annual between 151 and 180 then '151-180 days'
        when days_to_annual between 181 and 210 then '181-210 days'
        when days_to_annual between 211 and 240 then '211-240 days'
        when days_to_annual between 241 and 270 then '241-270 days'
        when days_to_annual between 271 and 300 then '271-300 days'
        when days_to_annual between 301 and 330 then '301-330 days'
        when days_to_annual between 331 and 360 then '331-360 days'
        else '361+ days'
    end as  period,
    count(*) as customers,
    round(avg(days_to_annual), 1) as avg_days
from days_taken
group by period
order by min(days_to_annual);


-- 11.  How many customers downgraded from a pro-monthly to a basic monthly plan in 2020? 


with customer_plans as (
    select
        customer_id,
        plan_id,
        start_date,
        lead(plan_id,1) over (
            partition by customer_id
            order by start_date
        )as next_plan,
        lead(start_date,1) over (
            partition by customer_id
            order by start_date
        ) as next_plan_date
    from subscriptions
)

select count(distinct customer_id) as downgraded_customers
from customer_plans
where plan_id = 2
  and next_plan = 1
  and next_plan_date between '2020-01-01' and '2020-12-31';





 


