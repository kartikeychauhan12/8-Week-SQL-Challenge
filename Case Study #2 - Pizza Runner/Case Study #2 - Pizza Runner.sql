                                        
			                                  /*     Data Cleaning & Transformation     */
 
/* 
 
                                                                      Table: customer_orders
												  
We can see that there are In the exclusions column, there are missing/ blank spaces ' ' and null values. 
In the extras column, there are missing/ blank spaces ' ' and null values.

Our course of action to clean the table: Create a temporary table with all the columns Remove null values in exlusions and 
extras columns and replace with blank space ' ' .

*/


  Select order_id, customer_id, pizza_id, 
  CASE WHEN exclusions IS null OR exclusions LIKE 'null' THEN ' ' ELSE exclusions
  END AS exclusions,
  CASE WHEN extras IS NULL or extras LIKE 'null' THEN ' ' ELSE extras
  END AS extras, order_time
  into customer_orders_temp 
  from customer_orders ;


/* 
                                                                      Table: runner_orders 

Our course of action to clean the table: 
In pickup_time column, remove nulls and replace with blank space ' '. 
In distance column, remove "km" and nulls and replace with blank space ' '. 
In duration column, remove "minutes", "minute" and nulls and replace with blank space ' '. 
In cancellation column, remove NULL and null and and replace with blank space ' '.

*/

  SELECT  order_id, runner_id,  
  CASE WHEN pickup_time LIKE 'null' THEN ' 'ELSE pickup_time END AS pickup_time,
  CASE WHEN distance LIKE 'null' THEN ' ' WHEN distance LIKE '%km' THEN TRIM('km' from distance) ELSE distance 
  END AS distance,
  CASE WHEN duration LIKE 'null' THEN ' '
	   WHEN duration LIKE '%mins' THEN TRIM('mins' from duration)
	   WHEN duration LIKE '%minute' THEN TRIM('minute' from duration)
	   WHEN duration LIKE '%minutes' THEN TRIM('minutes' from duration)
	   ELSE duration END AS duration,
  CASE WHEN cancellation IS NULL or cancellation LIKE 'null' THEN ' ' ELSE cancellation
  END AS cancellation
  into runner_orders_temp
  FROM runner_orders ;


-- Now we alter the pickup_time, distance and duration columns to the correct data type.

ALTER TABLE runner_orders_temp ALTER COLUMN distance FLOAT;
ALTER TABLE runner_orders_temp ALTER COLUMN duration INT;
ALTER TABLE runner_orders_temp ALTER COLUMN pickup_time DATETIME;

 
  

 /*           
                                                         Table : pizza_recipes (Optional) 

                 Normalized the Pizza_recipes table such that each row has pizza_id and its corresponding one topping.
                Having any form of a list within a cell is not a great way to proceed from a data or analytical standpoint. 
*/


create table pizza_recipes_temp
(
 pizza_id int,
    toppings int);
insert into pizza_recipes_temp
(pizza_id, toppings) 
values
(1,1),
(1,2),
(1,3),
(1,4),
(1,5),
(1,6),
(1,8),
(1,10),
(2,4),
(2,6),
(2,7),
(2,9),
(2,11),
(2,12);

                                                            /* A. Pizza Metrics */



-- Q1 How many pizzas were ordered?

     select COUNT(pizza_id) as pizza_ordered from customer_orders ;


-- Q2 How many unique customer orders were made?

      select count(distinct(order_id)) as unique_order_count from customer_orders ;
		

-- Q3 How many successful orders were delivered by each runner?

	  select runner_id ,count(order_id) as [successful orders] from runner_orders_temp
	  where distance != 0
	  group by runner_id ;


-- Q4 How many of each type of pizza was delivered?
      
	  select c.pizza_id , COUNT(c.order_id) as successful_deliver from customer_orders c
	  inner join
	  runner_orders_temp r on r.order_id = c.order_id
	  where r.distance  != 0
	  group by c.pizza_id ;



-- Q5 How many Vegetarian and Meatlovers were ordered by each customer?


         Select CAST(customer_id AS NVARCHAR(100)) as customer_id , CAST(pizza_name AS NVARCHAR(100)) as pizza_name,
	 COUNT(cast (pizza_name as nvarchar(100))) as order_count  from customer_orders_temp c
	 inner join 
	 pizza_names p on p.pizza_id = c.pizza_id
	 group by CAST(customer_id AS NVARCHAR(100)), CAST(pizza_name AS NVARCHAR(100))
	 order by customer_id ;



-- Q6 What was the maximum number of pizzas delivered in a single order?

          select Top 1 c.order_id , Count( pizza_id) as Max_pizza_deliver 
	  from customer_orders_temp c
	  inner join 
	  runner_orders_temp r on r.order_id = c.order_id
	  where distance != 0
	  group by c.order_id
	  order by Max_pizza_deliver desc ;


-- Q7 For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
      
	  select c.customer_id , 
	  Sum (Case when c.exclusions != ' ' or c.extras != ' '  then  1  else  0  End ) as at_least_1_change,
	  Sum (Case when c.exclusions = ' ' and c.extras  = ' '  then  1  else  0  End ) as no_change
          from customer_orders_temp c
	  inner join 
	  runner_orders_temp r on r.order_id = c.order_id
	  where r.distance != 0 
	  group by c.customer_id
	  ORDER BY c.customer_id ;



-- Q8 How many pizzas were delivered that had both exclusions and extras?
	  
	  select COUNT(pizza_id) as pizza_count_w_exclusions_extras
	  from customer_orders_temp c
	  inner join 
	  runner_orders_temp r on r.order_id = c.order_id
	  where distance != 0 and exclusions != ' ' and extras != ' ' ;


-- Q9 What was the total volume of pizzas ordered for each hour of the day?
      
	  select DATEPART(HOUR , order_time) as Hour_of_day , 
	  COUNT(order_id) as pizza_count from customer_orders_temp
	  group by DATEPART(HOUR , order_time) ;
	  


-- Q10 What was the volume of orders for each day of the week?

       SELECT FORMAT(DATEADD(DAY, 2, order_time),'dddd') AS day_of_week, 
       COUNT(order_id) AS total_pizzas_ordered
       FROM customer_orders_temp
       GROUP BY FORMAT(DATEADD(DAY, 2, order_time),'dddd') ;


                                           
										   
                                 			      /* B. Runner and Customer Experience  */


-- Q1 How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

	  select DATEDIFF(DAY, '2021-01-01',registration_date) / 7 + 1 AS week_number ,  
	  count(runner_id) as Runners_signed
	  from runners
	  group by DATEDIFF(DAY, '2021-01-01',registration_date) / 7 + 1 ;


-- Q2 What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

	  select runner_id ,AVG(DATEDIFF(MINUTE, order_time, pickup_time)) 
	  AS average_arrival_time_minutes
	  from customer_orders_temp c
	  inner join 
	  runner_orders_temp r on r.order_id = c.order_id
	  where distance != 0
	  group by runner_id ;
	

-- Q3 Is there any relationship between the number of pizzas and how long the order takes to prepare?
      
	  
	  with cte as (select c.order_id,COUNT(pizza_id) as num_piza,DATEDIFF(MINUTE , 
	  order_time,pickup_time) as duration
	  from customer_orders_temp c
	  inner join 
	  runner_orders_temp r on r.order_id = c.order_id
	  where distance != 0
	  group by c.order_id,DATEDIFF(MINUTE , order_time,pickup_time) )
	  select num_piza,AVG(duration) as avg_prepare_time from cte 
	  group by num_piza ;




-- Q4 What was the average distance travelled for each customer?

          select customer_id , AVG(distance) as avg_distance from customer_orders_temp c
	  inner join
	  runner_orders_temp r on r.order_id =c.order_id
	  where distance != 0
	  group by customer_id ;



-- Q5 What was the difference between the longest and shortest delivery times for all orders?

         with cte as (select order_id ,duration from runner_orders_temp 
	  where duration != 0)
	  select (Max(duration) - Min(duration)) as diff_delivery from cte ;


-- Q6 What was the average speed for each runner for each delivery and do you notice any trend for these values?


          select runner_id ,c.order_id, Round(distance/duration * 60 ,1) 
	  as Speed_kmh  from customer_orders_temp c 
	  join
	  runner_orders_temp r on r.order_id=c.order_id
	  where distance != 0
	  group by runner_id ,c.order_id ,Round(distance/duration * 60 ,1);


-- Q7 What is the successful delivery percentage for each runner?

        with cte as (select runner_id,COUNT(runner_id) as Total_recieve_del from runner_orders_temp
	group by runner_id)
        ,cte1 as (select runner_id,COUNT(runner_id) as successful_del from runner_orders_temp
	where distance != 0
	group by runner_id)
	select c.runner_id , Total_recieve_del ,successful_del , 
	Cast((1.0* successful_del/Total_recieve_del)*100 as decimal (5,1))
	as successful_pct from cte c
	inner join 
	cte1 c1 on c.runner_id = c1.runner_id ;


	                                         
		                                             /*  C. Ingredient Optimisation  */


-- Q1 What are the standard ingredients for each pizza? 

	  with cte as (select p.pizza_id ,Cast (topping_name as nvarchar(20)) as  topping_name
	  from pizza_recipes_temp p
	  inner join 
	  pizza_toppings t on t.topping_id =  p.toppings)
	  select pizza_id , STRING_AGG(topping_name  , ' , ') as topping_name  from cte 
	  group by pizza_id ;


	  

-- Q2 What was the most commonly added extra?

         with cte as (select top 1 extras , count (extras) 
	 as extras_counted from customer_orders_temp
	 where extras != ' '
	 group by extras 
	 order by extras_counted desc)
	 select extras ,topping_name  from cte c
	 inner join 
	 pizza_toppings p on p.topping_id = c.extras ;


-- Q3 What was the most common exclusion?

          with cte as (select Top 1  exclusions , 
	  count(exclusions) as Most_common from customer_orders_temp
	  where exclusions != ' '
	  group by exclusions
	  order by Most_common desc)
	  select exclusions,topping_name from cte c
	  join 
	  pizza_toppings  p on p.topping_id =c.exclusions ;


   
	 	                                             /*  D. Pricing and Ratings */


-- Q1 If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes 
--    how much money has Pizza Runner made so far if there are no delivery fees?

          select SUM(case when pizza_id=1 then 12 
	  when pizza_id=2 then 10 end) as Total_profit
	  from customer_orders_temp c
	  inner join
	  runner_orders_temp r on r.order_id=c.order_id
	  where distance != 0


-- Q3 The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
--    how would you design an additional table for this new dataset - generate a schema for this new table and insert 4
--    your own data for ratings for each successful customer order between 1 to 5.

   create table ratings (
   order_id integer,
   rating integer);
   insert into ratings
   (order_id, rating)
   values
   (1,3),
   (2,5),
   (3,3),
   (4,1),
   (5,5),
   (7,3),
   (8,4),
   (10,3);

-- Q4 Using your newly generated table - can you join all of the information together to form a table 
--    which has the following information for successful deliveries?
/* 
   customer_id
   order_id
   runner_id
   rating
   order_time
   pickup_time
   Time between order and pickup
   Delivery duration
   Average speed
   Total number of pizzas
*/

      select c.customer_id, c.order_id, r.runner_id, ratings.rating, c.order_time,
      r.pickup_time, datediff(minute, order_time, pickup_time) as Time_bw_Order_Pickup,
      r.duration, round(avg(r.distance*60/r.duration),1) as avgspeed, count(c.pizza_id) as PIzzaCount
      from customer_orders_temp c
      inner join runner_orders_temp r
      on c.order_id = r.order_id
      inner join ratings
      on ratings.order_id = c.order_id
      group by c.customer_id, c.order_id, r.runner_id, ratings.rating, c.order_time,
      r.pickup_time, datediff(minute, order_time, pickup_time), r.duration
      order by customer_id;

         




-- Q5 If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner 
--    is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

          with cte as (select SUM(case when pizza_id=1 then 12 
	  when pizza_id=2 then 10 end) as Total_profit
	  from customer_orders_temp c
	  inner join
	  runner_orders_temp r on r.order_id=c.order_id
	  where distance != 0 )
          ,cte1 as (select  
	  SUM(distance * 0.3) as delivery_fee
	  from runner_orders_temp
	  where distance != 0 )

	  select Total_profit -(select * from cte1) as  Final_amount from cte 
											 
											
						             
                                                                        /* Bonus Questions  */


-- Ques If Danny wants to expand his range of pizzas - how would this impact the existing data design? 

/* 
Because the pizza recipes table was modified to reflect foreign key designation for each topping linked 
to the base pizza, the pizza_id will have multiple 3s and align with the standard toppings (individually) within the toppings column.
In addition, because the data type was casted to an int to take advantage of numerical functions,insertion of data would not 
affect the existing data design, unlike the original dangerous approach of comma separated values in a singular row (list).

*/
