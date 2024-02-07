/* --------------------
   Case Study Data and Questions
   --------------------*/
CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


-- 1. What is the total amount each customer spent at the restaurant?

select sum(price),customer_id from dannys_diner.sales S join dannys_diner.menu M on S.product_id=m.product_id 
group by customer_id;

-- 2. How many days has each customer visited the restaurant?

select count(distinct order_date),customer_id from dannys_diner.Sales group by customer_id;

-- 3. What was the first item from the menu purchased by each customer?

with cte_product as(
Select product_name,customer_id, ROW_NUMBER() OVER (PARTITION BY s.customer_id order by order_date) as row_num from dannys_diner.sales s join dannys_diner.menu m on S.product_id=m.product_id)
select product_name,customer_id from cte_product where row_num=1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select product_name,count(s.product_id) as cnt from dannys_diner.sales s join dannys_diner.menu m on S.product_id=m.product_id group by s.product_id,product_name
order by cnt desc limit 1;

-- 5. Which item was the most popular for each customer?

select count(*),product_name,customer_id from dannys_diner.sales s join dannys_diner.menu m on S.product_id=m.product_id group by customer_id,product_name order by customer_id,count;

-- 6. Which item was purchased first by the customer after they became a member?

with first_purchase as(
select s.customer_id,product_name,row_number() Over (partition by s.customer_id order by s.customer_id) as row_num from dannys_diner.sales s join dannys_diner.menu m on S.product_id=m.product_id join dannys_diner.members m2 on m2.customer_id=s.customer_id where order_date>join_date
) 
select * from first_purchase where row_num=1;

-- 7. Which item was purchased just before the customer became a member?

-- 7. Which item was purchased just before the customer became a member?
With Rank as
(
Select  S.customer_id,
        M.product_name,
	Dense_rank() OVER (Partition by S.Customer_id Order by S.Order_date) as Rank
From dannys_diner.Sales S
Join dannys_diner.Menu M
ON m.product_id = s.product_id
JOIN dannys_diner.Members Mem
ON Mem.Customer_id = S.customer_id
Where S.order_date < Mem.join_date  
)
Select customer_ID, Product_name
From Rank
Where Rank = 1


-- 8. What is the total items and amount spent for each member before they became a member?

select count(*),sum(price),s.customer_id from dannys_diner.sales s join dannys_diner.members m2 on m2.customer_id=s.customer_id join dannys_diner.menu m on S.product_id=m.product_id where order_date<join_date group by s.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

with total_points as (select customer_id,
case when m.product_name='sushi' then price*20
else price*10
end as points from 
dannys_diner.menu m join
dannys_diner.sales s
on s.product_id=m.product_id)
 
select customer_id,sum(points) from total_points group by customer_id order by customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

With Week_points as (
select s.customer_id, order_date,
case When order_date>=join_date and order_date<join_date+7 then price*20 
When not order_date>=join_date and order_date<join_date+7 and product_name='sushi' then price*20 
else price*10 
  end
  as points from
dannys_diner.members m join
dannys_diner.sales s on m.customer_id=s.customer_id
join dannys_diner.menu m2 on 
s.product_id=m2.product_id)

select customer_id,sum(points) from Week_points where order_date<='2021-01-31' group by customer_id

