--- show plain tables

SELECT * 
FROM foodie_fi.plans;

/* we are going to omit mentioning the root 
of the only schema (foodie_fi) to simplyfy retrieving queries*/
SET
  search_path = foodie_fi;
  
SELECT * 
FROM subscriptions
LIMIT 10;


---	Customer plan evolution

SELECT
  s.customer_id,
  p.plan_name, 
  p.plan_id,  
  s.start_date
FROM plans p
JOIN subscriptions s
  ON p.plan_id = s.plan_id
	WHERE s.customer_id IN (1,11,15,19);


--Q1:

SELECT 
	COUNT( 
		DISTINCT customer_id 
		) as different_customers
FROM subscriptions

--Q2: this one

SELECT
  DATE_PART('month'
			, start_date
		   ) AS month_date,-- Cast start_date as month in numerical format
  COUNT(s.customer_id) AS trial_distributions
FROM subscriptions s
JOIN plans p
  ON s.plan_id = p.plan_id
	WHERE p.plan_name = 'trial'
GROUP BY month_date
ORDER BY month_date;


---test: month name appear

SELECT
  TO_CHAR (start_date,
		   'month'
		  ) AS month_name, -- Cast start_date as month in numerical format
  COUNT(s.customer_id) AS trial_distributions
FROM subscriptions s
JOIN plans p
  ON s.plan_id = p.plan_id
	WHERE p.plan_name = 'trial'
GROUP BY month_name
ORDER BY  month_name;




--Q3

SET
  search_path = foodie_fi;

SELECT 
  p.plan_name,
  COUNT(s.customer_id
	   ) AS num_of_events
FROM subscriptions s
JOIN plans p
  ON s.plan_id = p.plan_id
	WHERE s.start_date >= '2021-01-01'
GROUP BY p.plan_id, p.plan_name
ORDER BY p.plan_id;


--Q4


DROP TABLE IF EXISTS total_cust;

CREATE TEMP TABLE total_cust AS (
    SELECT 
		COUNT(DISTINCT customer_id
			) AS different_customers
    FROM subscriptions 
				);
WITH chur AS (
    SELECT COUNT(	
		DISTINCT customer_id
			) AS chur_cust
    FROM subscriptions
    WHERE plan_id = 4    /* Plan_id = 4  ---> plan_name = 'churn' */
				  )
SELECT 
	   chur.chur_cust AS churned_customers,
       CAST(chur.chur_cust  AS FLOAT) / 
	   CAST(total_cust.different_customers AS FLOAT) * 1E2 
	   				  AS percent_churned
FROM total_cust, chur;


--Q5  --

DROP TABLE IF EXISTS cust_plan_lead;

CREATE TEMP TABLE cust_plan_lead AS(
    SELECT *, 
        LEAD (plan_id, 1) 
        OVER (PARTITION BY customer_id 
			 ORDER BY customer_id) 
								AS next_plan
    FROM subscriptions
									);
WITH churn_filter  AS (
    SELECT 
	COUNT (
		DISTINCT customer_id
			) AS trial_to_churn
    FROM cust_plan_hist
    WHERE  plan_id = 0      /* First trial.. */
		AND next_plan = 4   /* ...then churn */
						)		
SELECT		  
		 trial_to_churn,
		 CAST (trial_to_churn AS FLOAT)/
		 CAST ((SELECT                            
					COUNT(DISTINCT customer_id)   
      		    FROM subscriptions)     
			   AS FLOAT) * 1E2 
			   		   AS churned_percentage
		 
FROM churn_filter , total_cust;   /* total_cust table was created in Q4*/




--Q6

WITH pat AS (
  SELECT 
    s.customer_id,
    s.start_date,
    p.plan_name,
    LEAD(p.plan_name) 
	OVER(PARTITION BY s.customer_id 
		 ORDER BY p.plan_id) AS plan_after_trial
  FROM subscriptions s
  	JOIN plans p 
	  ON p.plan_id = s.plan_id
			)
SELECT 
  plan_after_trial,
  COUNT(*) AS cust_per_plan,
  CAST
  (COUNT(*) * 1E2 AS FLOAT)/
  (SELECT 
   	 COUNT(DISTINCT customer_id) 
   FROM subscriptions) 
   		   AS percentage
FROM pat
WHERE plan_name = 'trial'
GROUP BY plan_after_trial;
	
--Q7--

WITH odh AS (   
  SELECT
    customer_id,
    plan_id,
  	start_date,
    LEAD(start_date)                  /* Select 1 date ahead */
	OVER (PARTITION BY customer_id    /* for each customer   */
		  ORDER BY start_date   
    	  ) AS one_day_ahead
  FROM subscriptions
  WHERE start_date <= '2020-12-31'    /* untill end of the year */
			)
SELECT
	plan_id, 
	ROUND(1E2 * COUNT(DISTINCT customer_id)/
			 (SELECT 
				COUNT(DISTINCT customer_id) 
			  FROM subscriptions),
		  1) AS percentage_of_plan,
	COUNT(DISTINCT customer_id)  AS different_customers
FROM odh                       /* all this selections are framed as per the odh cte*/
WHERE one_day_ahead IS NULL    /* and removing the leads of the last days of subscription */
GROUP BY plan_id;

--Q8

SELECT 
	COUNT(DISTINCT customer_id) AS customers_in_annual_plan
FROM subscriptions
WHERE plan_id = 3
  AND start_date <= '2020-12-31';




---Q9 

WITH trial AS (
    SELECT 
		customer_id,
		start_date AS trial_date
    FROM subscriptions 
    WHERE plan_id = 0
			  ),
	 annual_upgrade AS (
    SELECT 
		customer_id, 
		start_date AS annual_date 
    FROM subscriptions 
    WHERE plan_id = 3
						)
SELECT 
	CAST(
		AVG(annual_date - trial_date) AS INTEGER) 
			AS trial_to_annual_avg_days
FROM trial t
	JOIN annual_upgrade au
		ON t.customer_id = au.customer_id;


--Q10:

WITH 
	trial AS (
  SELECT 
    customer_id, 
    start_date AS t_date
  FROM subscriptions
  WHERE plan_id = 0
	         ), 
				  
	 annual AS (
  SELECT 
    customer_id, 
    start_date AS a_date
  FROM subscriptions
  WHERE plan_id = 3
	 		   ), 
					
	 day_bucket AS (
  SELECT 
    WIDTH_BUCKET(a.a_date - t.t_date, 
				 0, 
				 365, 
				 12) AS days_to_upgrade
	FROM annual AS a
	JOIN trial AS t
		ON t.customer_id = a.customer_id
				   )
SELECT 
  (' From ' || days_to_upgrade * 30 ||
   ' to ' || days_to_upgrade * 30 ||
   ' days') AS day_period, 
   COUNT(*) AS num_of_customers
FROM day_bucket
GROUP BY days_to_upgrade
ORDER BY days_to_upgrade;

--Q11


SELECT COUNT(*) AS pro_month_to_basic
FROM cust_plan_lead                         /* temp table used in Q5*/
WHERE plan_id=2 
	AND next_plan=1;


---- or


WITH npi AS (
  SELECT 
    s.customer_id,  
  	p.plan_id,
	  LEAD(p.plan_id) 
	  OVER ( PARTITION BY s.customer_id
			 ORDER BY s.start_date) 
					AS next_plan_id
  FROM subscriptions s
  JOIN plans p
    ON s.plan_id = p.plan_id
 WHERE DATE_PART('year', start_date) = 2020
)
  
SELECT 
  COUNT(customer_id) AS pro_month_to_basic
FROM npi
WHERE plan_id = 2
  AND next_plan_id = 1;



