
#  Case Study #3: Foodie-Fi

<p align="center">
<img src="https://github.com/GBlanch/SQL-weekly-challenges/assets/136500426/8dc3143e-8907-4546-8fd3-163f50c35d61"  width="70%" height="70%">
  
Note: The plain sql script for all queries without any data output is located [here](https://github.com/GBlanch/SQL-weekly-challenges/blob/main/3.Foodie_fi/foodie_fi_main_script.sql)


## Introduction


Foodie-Fi is a subscription-based and food-related streaming service, akin to Netflix but focused solely on cooking shows. 

During sign-up, there are two subscription plans for customers to choose from:

- Basic: $9.90 monthly, provides limited access to streaming videos.
- Pro: $19.90 monthly or $199 annually, offers unlimited watch time and the ability to download videos for offline viewing.

Customers can opt for a 7-day free trial which will automatically continue to the Pro monthly subscription plan unless they cancel, downgrade to Basic, or upgrade to an annual Pro plan.

## Data Analysis Questions


1.	How many customers has Foodie-Fi ever had?

<p align="center">
  <img src="https://github.com/GBlanch/SQL-weekly-challenges/assets/136500426/77650e9f-567e-454e-b6b4-db1b35c68708" alt="image">
</p>


2.	What is the monthly distribution of trial plan start_date values for our dataset?

<p align="center">
  <img src="https://github.com/GBlanch/SQL-weekly-challenges/assets/136500426/9c78b5dc-17e0-4843-b083-15453dc58da7" alt="image">
</p>




3.	What plan start_date values occur after the year 2020 for our dataset?

<p align="center">
  <img src="https://github.com/GBlanch/SQL-weekly-challenges/assets/136500426/d71a9555-dab8-4a42-8702-85db0600c57e" alt="image">
</p>





4.	What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

<p align="center">
  <img src="https://github.com/GBlanch/SQL-weekly-challenges/assets/136500426/dba014a6-df64-4f20-b92d-913c86f011a2" alt="image">
</p>




5.	How many customers have churned straight after their initial free trial - what percentage is this rounded to 1 decimal place?

<p align="center">
  <img src="https://github.com/GBlanch/SQL-weekly-challenges/assets/136500426/ccae51e4-911e-48ee-b1f2-ed0178effde3" alt="image">
</p>



6.	What is the number and percentage of customer plans after their initial free trial?


<p align="center">
  <img src="https://github.com/GBlanch/SQL-weekly-challenges/assets/136500426/125e2fe4-79b5-4fa4-8160-47c68a84cb6d" alt="image">
</p>



7.	What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?


<p align="center">
  <img src="https://github.com/GBlanch/SQL-weekly-challenges/assets/136500426/8f232330-ec68-4fc0-b6e8-6f4b9aca2623" alt="image">
</p>



8.	How many customers have upgraded to an annual plan in 2020?


<p align="center">
  <img src="https://github.com/GBlanch/SQL-weekly-challenges/assets/136500426/9a19ca8e-8556-42c0-971a-1436627fba21" alt="image">
</p>



9.	How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?


<p align="center">
  <img src="https://github.com/GBlanch/SQL-weekly-challenges/assets/136500426/b6ac1d24-d405-47bc-bd05-7c50bac99718" alt="image">
</p>


10.	Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)?


<p align="center">
  <img src="https://github.com/GBlanch/SQL-weekly-challenges/assets/136500426/dc36a5b2-bba8-4972-b68b-354509772282" alt="image">
</p>


<p align="center">
  <img src="https://github.com/GBlanch/SQL-weekly-challenges/assets/136500426/4491a87c-db52-4088-9ad6-64dff84f9d21" alt="image">
</p>


11.	How many customers downgraded from a pro monthly to a basic monthly plan in 2020?


<p align="center">
  <img src="https://github.com/GBlanch/SQL-weekly-challenges/assets/136500426/475680df-90ca-4a6b-bb45-761597869219" alt="image">
</p>




