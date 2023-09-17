
SET search_path = data_bank;

--Part A. Customer Nodes Exploration
--Q1. How many unique nodes are there on the Data Bank system?

SELECT 
	COUNT(DISTINCT node_id) AS unique_nodes
FROM customer_nodes;


--Q2.What is the number of nodes per region?


SELECT
  region_name, 
  COUNT(DISTINCT c.node_id) AS nodes
FROM regions r
JOIN customer_nodes c
  ON r.region_id = c.region_id
GROUP BY r.region_name
ORDER BY r.region_name;

--Q3.How many customers are allocated to each region?


SELECT 
  r.region_name,
  COUNT(DISTINCT c.customer_id) AS customers
FROM customer_nodes c
JOIN regions r
  ON c.region_id = r.region_id
GROUP BY r.region_name
ORDER BY r.region_name;


---Q4.How many days on average are customers reallocated 
--    to a different node?

WITH tnd AS (
  SELECT 
    SUM(end_date - start_date) AS total_node_days,
	customer_id, 
    node_id
  FROM customer_nodes
  WHERE end_date != '9999-12-31'
  GROUP BY customer_id, 
		   node_id, 
		   start_date, 
		   end_date
			)
SELECT 
	ROUND(
		  AVG(total_node_days),
		  2)	
			AS node_days_average
FROM tnd;


---Q5.What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
  --column day not defined

WITH customerDates AS (
  SELECT 
    customer_id,
    region_id,
    node_id,
    MIN(start_date) AS first_date
  FROM customer_nodes
  GROUP BY customer_id, region_id, node_id
),
reallocation AS (
  SELECT
    customer_id,
    region_id,
    node_id,
    first_date,
    DATE_PART('day',
			  AGE(first_date ,
             LEAD(first_date) OVER(PARTITION BY customer_id 
                                   ORDER BY first_date))) AS moving_days
  FROM customerDates  ---up to here it's good
)

SELECT 
  DISTINCT r.region_id,
  rg.region_name,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY r.moving_days) OVER(PARTITION BY r.region_id) AS median,
  PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY r.moving_days) OVER(PARTITION BY r.region_id) AS percentile_80,
  PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY r.moving_days) OVER(PARTITION BY r.region_id) AS percentile_95
FROM reallocation r
JOIN regions rg ON r.region_id = rg.region_id
WHERE moving_days IS NOT NULL;

----
---




---Customer Transactions 

--Q1.What is the unique count and total amount for each transaction type?


SELECT 
  txn_type AS transaction_type,
  COUNT(*) AS transaction_count,
  SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY txn_type
ORDER BY txn_type;

--Q2.What is the average total historical deposit counts and amounts for all customers?


WITH dc_da AS (
  SELECT 
    customer_id, 
    COUNT(customer_id) AS deposit_count, 
    AVG(txn_amount) AS deposit_amount
  FROM customer_transactions
  WHERE txn_type = 'deposit'
  GROUP BY customer_id
			 )
SELECT 
  ROUND(
	  AVG(deposit_count)
  		) AS avg_deposit_count, 
  ROUND(
	  AVG(deposit_amount)
  		) AS avg_deposit_amount
FROM dc_da;



--Q3.For each month - how many Data Bank customers make more than 1 deposit 
--and at least either 1 purchase or 1 withdrawal in a single month?

WITH mpdw AS (       /*month, purchase, deposit, withdrawal*/
	SELECT
		EXTRACT(
			MONTH 
		FROM txn_date
				) AS month_part,
		TO_CHAR(
				txn_date,
				'Month'
				) AS month,
		customer_id,
		SUM(
			CASE 
				WHEN txn_type = 'purchase' 
				THEN 1 
				ELSE 0 END
			) 	  AS purchase,
		SUM(
			CASE 
				WHEN txn_type = 'deposit' 
				THEN 1 
				ELSE 0 END
		   )      AS deposit,
		SUM(
			CASE 
				WHEN txn_type = 'withdrawal' 
				THEN 1 
				ELSE 0 END
		    )     AS withdrawal
	FROM customer_transactions
	GROUP BY
		month_part,
		month,
		customer_id
)
SELECT 
	month,
	COUNT(customer_id) AS customer_count
FROM mpdw
WHERE deposit > 1 
	AND (purchase >= 1 
	OR withdrawal >= 1)
GROUP BY 
	month_part,
	month
ORDER BY 
	month_part;


--Q4.What is the closing balance for each customer at the end of the month? 
--Also show the change in balance each month in the same table output.

--As Danny hinted, we need to check the total range of months avialable:

SELECT
  DATE_TRUNC('week', txn_date)::DATE AS month,
  COUNT(
	  DISTINCT customer_id) AS record_count
FROM customer_transactions
WHERE txn_date >= '2020-01-01'
GROUP BY month
ORDER BY month;
  
/*  Now we know that out time span will be from January to April, therefore*/

--1st CTE: for every unique customer, let us compute 4-month intervals 

WITH eomi AS ( /*end_of_month_intervals*/
  SELECT
	DISTINCT customer_id,
	('2020-01-31'::DATE + GENERATE_SERIES(0,3) *  /*from end of Jan, 4 intervals of a 1 month span */
	 INTERVAL '1 MONTH')::DATE AS eom_intervals
  FROM customer_transactions
						),
--2nd CTE : Based on each transaction_date,  compute a list of last day of the month..

	 eomt AS (  /*end_of_month_transactions*/
	  SELECT 
		customer_id, 
		(DATE_TRUNC('month', 
					txn_date
				   ) + INTERVAL '1 MONTH' - INTERVAL '1 DAY'   /*equivalency of EOMONTH()*/
				   )::DATE AS eom_transactions, 
		SUM(CASE 
				WHEN txn_type IN ('purchase', 
								  'withdrawal')              /*..and compute the summation of all purch. and withd.,*/
				THEN txn_amount * -1                         /*with outbound transaction as minus.. */
				ELSE txn_amount END						     /*..or else leave it as is.*/
			) 		 AS transactions  
	  FROM customer_transactions
	  GROUP BY 
		customer_id, 
		txn_date 
	),
--3rd CTE: Compute the summation of total monthly transtacions..

	 sot AS (  /*summation_of_transactions*/
		  SELECT 
			mi.customer_id, 
			mi.eom_intervals, 
			SUM(mt.transactions) OVER (PARTITION BY mi.customer_id  /*..sectioning only by costumer_id */
									   ORDER BY     mi.eom_intervals 
									 ) AS eom_balance,	 
			SUM(mt.transactions) OVER (PARTITION BY mi.customer_id, /*..sectioning only by costumer_id,*/
													mi.eom_intervals /*..and end_of_month too*/
									   ORDER BY     mi.eom_intervals
									 ) AS monthly_change

		  FROM  eomi  mi
		  LEFT JOIN eomt mt
			ON  mi.customer_id = mt.customer_id
			AND mi.eom_intervals = mt.eom_transactions
							)
--Main query: For each customer, display the monthly and closing balance with their transaction date. 

SELECT 
	  customer_id, 
	  eom_intervals AS end_of_month_intervals, 
	  COALESCE(monthly_change, 
			   0) AS monthly_balance,        /*Select a zero if the monthly_change is NaN*/
	  MIN(eom_balance) AS closing_balance
 FROM sot
 GROUP BY 
  customer_id, 
  eom_intervals, 
  monthly_change
 ORDER BY 
  customer_id, 
  eom_intervals,
  monthly_change;
  
  ---
  --
  

  
