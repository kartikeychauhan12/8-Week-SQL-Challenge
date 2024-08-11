
                                                 /*  Case Study Questions  */


-- Q1 What is the total amount each customer spent at the restaurant?
   
   select s.customer_id, sum(m.price) as total_amt  from sales s
   inner join 
   menu m  on s.product_id = m.product_id 
   group by s.customer_id ;

-- Q2 How many days has each customer visited the restaurant?

   select s.customer_id , COUNT(distinct s.order_date) as days from sales s
   inner join 
   menu m  on s.product_id = m.product_id 
   group by s.customer_id ;


-- Q3 What was the first item from the menu purchased by each customer?
     
   with cte as (select  s.customer_id , m.product_name , 
   ROW_NUMBER () over (partition by s.customer_id order by s.order_date) as rn from sales s
   inner join  
   menu m  on s.product_id = m.product_id )
   select customer_id,product_name from cte 
   where rn = 1 ;

   
-- Q4 What is the most purchased item on the menu and how many times was it purchased by all customers?

   select Top 1 m.product_name,COUNT(m.product_name) as times_purchsed from sales s
   inner join 
   menu m  on s.product_id = m.product_id
   group by m.product_name
   order by times_purchsed desc ;
   


-- Q5 Which item was the most popular for each customer?

   with cte as (select s.customer_id,m.product_name , Count(m.product_name) as order_count ,
   DENSE_RANK() over (partition by s.customer_id order by Count(m.product_name) desc ) as rnk
   from sales s
   inner join 
   menu m  on s.product_id = m.product_id
   group by s.customer_id , m.product_name)
   select customer_id,product_name,order_count from cte 
   where rnk = 1 ;

-- Q6 Which item was purchased first by the customer after they became a member?
      
	with cte as (select mem.customer_id , product_name , order_date , join_date, 
	DENSE_RANK() over (partition by mem.customer_id order by s.order_date) as rnk  from sales s
	inner join 
	members mem on mem.customer_id =s.customer_id
	inner join 
	menu m on m.product_id =s.product_id
	where order_date >= join_date)
	select customer_id,product_name, order_date, join_date from cte 
	where rnk = 1 ;

	  
-- Q7 Which item was purchased just before the customer became a member?

    with cte as (select mem.customer_id , product_name , order_date , join_date, 
	DENSE_RANK() over (partition by mem.customer_id order by s.order_date desc) as rnk  from sales s
	inner join 
	members mem on mem.customer_id =s.customer_id
	inner join 
	menu m on m.product_id =s.product_id
	where order_date < join_date)
	select customer_id,product_name, order_date, join_date from cte 
	where rnk = 1 ;


	
-- Q8 What is the total items and amount spent for each member before they became a member?
 
    select  mem.customer_id , STRING_AGG(product_name , ' , ') as items , COUNT(product_name) as total_items
	, sum(price) as amt_spent from sales s
	inner join 
	members mem on mem.customer_id =s.customer_id
	inner join 
	menu m on m.product_id =s.product_id
	where order_date < join_date
	group by mem.customer_id ;
      




-- Q9 If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

      with cte as (select * , 
	  case when product_id = 1 then 20 * price else price*10 End as Points from menu)
	  select customer_id , Sum(Points) as total_points from sales s
	  inner join 
	  cte c on c.product_id = s.product_id
	  group by customer_id ;
	  
	 

-- Q10 In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
--     not just sushi - how many points do customer A and B have at the end of January?
 

       with cte as (select s.customer_id ,order_date, join_date , price,
	   case when (DATEDIFF (DAY, join_date,order_date) between 0 and  7)  then price * 20 
	   when (DATEDIFF (WEEK, join_date,order_date) != 1) then 0 else 0 end as points 
	   from sales s
	   inner join 
	   members mem on mem.customer_id=s.customer_id 
	   inner join 
	   menu m on m.product_id = s.product_id)
	   select customer_id , SUM(points) as Point from cte
	   group by customer_id;





/*                                                Bonus Questions
                                                
												
												Join All The Things
               The following questions are related creating basic data tables that Danny and his team can 
               use to quickly derive insights without needing to join the underlying tables using SQL.

*/

	  select s.customer_id,s.order_date , 
	  m.product_name,m.price , 
	  (Case when order_date >= join_date 
	  then 'Y' else 'N' end ) 
	  as Member from sales s
	  inner join
	  menu m on m.product_id = s.product_id
	  left join  
	  members mem on mem.customer_id=s.customer_id;


/*	                                                      Rank All The Things
       Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for 
       non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.
*/ 

     with cte as (select s.customer_id,s.order_date , 
	 m.product_name,m.price , 
	 (Case when order_date >= join_date 
	 then 'Y' else 'N' end ) as Member from sales s
	 inner join
	 menu m on m.product_id = s.product_id
	 left join  
	 members mem on mem.customer_id=s.customer_id ) 
	 select * ,
	 (Case when Member = 'Y' then dense_rank () 
	 over(partition by customer_id,Member 
	 order by order_date) 
	 else null end) as ranking
	 from cte ;





