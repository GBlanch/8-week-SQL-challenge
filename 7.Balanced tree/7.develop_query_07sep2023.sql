
SET search_path = balanced_tree;

--Sales Analysis:
--A1. What was the total quantity sold for all products?

/* Overall computing*/

SELECT
  SUM(s.qty) AS overall_sold
FROM sales s;

/* computing per product name*/

SELECT 
  product_name, 
  SUM(s.qty) AS sold_per_product
FROM sales s
JOIN product_details p
	ON s.prod_id = p.product_id
GROUP BY p.product_name
ORDER BY sold_per_product DESC;




--A2. What is the total generated revenue for all products before discounts?

/* Overall computing*/

SELECT 
	SUM (qty * price) AS overall_rev_before_disc
FROM sales;

/* Computing per product name*/

SELECT 
  p.product_name, 
  SUM(s.price) * SUM(s.qty) AS product_rev_before_disc
FROM sales s
JOIN product_details  p
	ON s.prod_id = p.product_id
GROUP BY p.product_name
ORDER BY product_rev_before_disc DESC;


--A3. What was the total discount amount for all products?

/* Overall computing*/


SELECT 
	CAST(
		SUM(qty * price * discount * 1E-2) 
		AS FLOAT)
				AS overall_discount
FROM sales;


/* Computing per product name*/

SELECT 
  p.product_name, 
  SUM(s.qty * s.price * s.discount * 1E-2) AS discount_per_product
FROM sales s
JOIN product_details p
	ON s.prod_id = p.product_id
GROUP BY p.product_name
ORDER BY discount_per_product DESC;


--Transaction Analysis
--B1. How many unique transactions were there?

SELECT
	COUNT(
		DISTINCT txn_id) AS unique_transactions
FROM sales;


--B2. What is the average unique products purchased in each transaction?

WITH tpc AS (
	SELECT
		txn_id,
		COUNT (DISTINCT prod_id) AS transacted_products_count
	FROM sales
	GROUP BY txn_id
			)
SELECT
	ROUND(
		AVG(transacted_products_count),0) AS avg_unique_products
FROM tpc;

--B3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?

WITH tr AS (
  SELECT
    txn_id,
    SUM(qty * price) AS transaction_revenue
  FROM sales
  GROUP BY txn_id
		   )
SELECT
   PERCENTILE_CONT(0.25) 
   			WITHIN GROUP(
				ORDER BY transaction_revenue
						) AS Q1,
   PERCENTILE_CONT(0.5) 
   			WITHIN GROUP(
				ORDER BY transaction_revenue
						) AS Q2,
   PERCENTILE_CONT(0.75)
   			WITHIN GROUP(
				ORDER BY transaction_revenue
						) AS Q3
FROM tr;

--B4. What is the average discount value per transaction?


WITH td AS (
	SELECT
		txn_id,
		SUM(price * qty * discount) * 1E-2 AS transact_discounts
	FROM sales
	GROUP BY txn_id
		   )
SELECT
	ROUND(
		AVG(transact_discounts),2) AS avg_transact_discounts
FROM td;


--B5. What is the percentage split of all transactions for members vs non-members?

WITH tc AS (
  SELECT
    member,
    COUNT(
		DISTINCT txn_id) AS transact_count
  FROM sales
  GROUP BY member
)

SELECT
  member,
  transact_count,
  ROUND(
	  transact_count * 100 /
	  (SELECT 
			SUM(transact_count) 
			FROM tc
	  ) 
		) AS percentage
FROM tc
GROUP BY member, transact_count
ORDER BY transact_count DESC;


--B6. What is the average revenue for member transactions and non-member transactions?

WITH r AS (
  SELECT
    member,
  	txn_id,
    SUM( qty * price) AS revenue
  FROM sales
  GROUP BY member, txn_id
		)

SELECT
	member,
     ROUND(
	   AVG(revenue),
	   2) AS avg_revenue
	  
FROM r
GROUP BY member
ORDER BY member DESC;

--Product Analysis
--C1. What are the top 3 products by total revenue before discount?


SELECT 
 	pd.product_name AS top_3_product_names,
 	pd.product_id AS top_3_product_ids,
    SUM( s.qty * s.price ) AS revenue_before_discount
FROM sales s
JOIN product_details pd 
  ON s.prod_id = pd.product_id
GROUP BY pd.product_id, pd.product_name
ORDER BY revenue_before_discount DESC
LIMIT (3);


--C2. What is the total quantity, revenue and discount for each segment?

SELECT 
  pd.segment_name,
  pd.segment_id,
  SUM(s.qty) AS total_quantity,
  SUM(s.qty * s.price * discount) AS total_discount,
  SUM(s.qty * s.price) AS total_revenue_without_discount
FROM sales s
JOIN product_details pd 
  ON s.prod_id = pd.product_id
GROUP BY pd.segment_name, pd.segment_id
ORDER BY total_discount DESC ;

--C3. What is the top selling product for each segment?


WITH tq_sr_tr AS (         /*total quantity, sold rank, total revenue*/
    SELECT
	  pd.segment_name,  
	  pd.segment_id,
      pd.product_name,
      SUM(s.qty) AS total_quantity,
      RANK() 
				OVER (PARTITION BY pd.segment_name
				ORDER BY SUM(s.qty ) DESC            /*------->top selling product*/
     			 		 ) AS sold_rank_per_segment, /*under quantity criteria and segment,*/
      SUM(s.qty * s.price) AS total_revenue          /*not total revenue*/
	FROM                                                
      sales AS s
      JOIN product_details pd 
		ON s.prod_id = pd.product_id
    GROUP BY
      pd.segment_name,
      pd.product_name,
	  pd.segment_id
  )
SELECT
  segment_name,  
  segment_id,
  product_name,
  total_quantity,
  total_revenue
FROM tq_sr_tr
WHERE sold_rank_per_segment = 1;


--C4. What is the total quantity, revenue and discount for each category?

SELECT
  pd.category_name,
  SUM(s.qty) AS total_quantity,
  SUM(s.qty * s.price) AS total_revenue,
  ROUND(
    	SUM(
			CAST(s.qty * s.price * s.discount AS numeric) * 1E-2),
    	1) AS total_discount
FROM
  sales s
JOIN product_details pd 
  ON s.prod_id = pd.product_id
GROUP BY pd.category_name
ORDER BY pd.category_name;


--C5. What is the top selling product for each category?

WITH srpc AS (    /*sold_rank_per_category*/
  SELECT 
    pd.product_name,
    pd.category_name, 
    pd.product_id,
    pd.category_id,
    SUM(s.qty) AS total_quantity,
    RANK() OVER (
      PARTITION BY pd.category_id 
      ORDER BY SUM (s.qty)  DESC) 
			   AS sold_rank_per_category
  FROM sales s
   JOIN product_details pd
    ON s.prod_id = pd.product_id
  GROUP BY 
	pd.product_name,
	pd.category_name,
	pd.product_id,
	pd.category_id
)

SELECT 
  product_name,
  category_name, 
  product_id,
  total_quantity
FROM srpc
WHERE sold_rank_per_category = 1;

--C6. What is the percentage split of revenue by product for each segment?

WITH pr AS (
  SELECT 
    pd.segment_name,
    pd.product_name,
    SUM (s.qty * s.price) AS product_revenue
  FROM sales s
  JOIN product_details pd 
    ON s.prod_id = pd.product_id
  GROUP BY 
	pd.segment_name, 
	pd.product_name
		   )

SELECT 
  segment_name,
  product_name,
  ROUND (CAST (product_revenue * 1E2 / 
	   		   SUM(product_revenue) OVER (PARTITION BY segment_name) 
			  AS numeric)
		 ,2) 
		 	  AS percent_per_segment
FROM pr
ORDER BY percent_per_segment DESC;

--C7. What is the percentage split of revenue by segment for each category?



WITH pr AS (
  SELECT 
    pd.category_name,
    pd.segment_name,
    SUM (s.qty * s.price) AS product_revenue
  FROM sales s
  JOIN product_details pd 
    ON s.prod_id = pd.product_id
  GROUP BY 
	pd.category_name, 
	pd.segment_name
			)

SELECT 
  category_name,
  segment_name,
  ROUND (CAST (product_revenue * 1E2 / 
	   		   SUM(product_revenue) OVER (PARTITION BY category_name) 
			  AS numeric)
		 ,2) 
		 	  AS percent_per_category
FROM pr
ORDER BY percent_per_category DESC;


--C8. What is the percentage split of total revenue by category?

WITH pr AS (
  SELECT 
    pd.category_name,
    SUM (s.qty * s.price) AS product_revenue
  FROM sales s
  JOIN product_details pd 
    ON s.prod_id = pd.product_id
  GROUP BY 
	pd.category_name
			)

SELECT 
  category_name,
  ROUND (CAST (product_revenue * 1E2 / 
	   		   SUM(product_revenue) OVER () 
			  AS numeric)
		 ,2) 
		 	  	AS percent_per_category
FROM pr
ORDER BY percent_per_segment DESC;

--C9. What is the total transaction “penetration” for each product? 
--(hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)

WITH tt_dt AS (                             /*total_transactions, distinct_transactions*/
  SELECT 
	DISTINCT s.prod_id, 
			 pd.product_name,
	(SELECT 
		COUNT(DISTINCT txn_id)   
	 FROM sales 
	)     AS total_transactions,	         /*this will compute and select them altogether,*/
    COUNT(                                   /*irrespective of their id.*/
		DISTINCT s.txn_id
		) AS distinct_transactions           /*this will compute and store them */
											 /*per each different id.*/

  FROM sales s
  JOIN product_details pd 
    ON s.prod_id = pd.product_id
  GROUP BY s.prod_id, pd.product_name
)

SELECT 
  product_name,  
  ROUND (CAST (distinct_transactions * 1E2 / 
	   		   total_transactions 
			  AS numeric)
		 ,2) 
		 	 	 AS penetration_percent
				 
FROM dt
ORDER BY penetration_percent DESC ;

----

