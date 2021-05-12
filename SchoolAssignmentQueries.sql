
/* A few queries I wrote for school assignments */

/* 
1. Joe’s Coffee chain sells products in 5 different product groups (as given in the products table):
Whole Beans/Tea, Beverages, Food, Merchandise and Add-ons.

The targets table in the joeCoffee database represents the weekly revenue goals for each outlet in
the chain, across the various product groups (except Add-ons, which does not have a target).
There is only 1 row for each outlet, indicating the same targets are used each week for the entire
month.

QUERY QUESTION: Write a query (or a set of queries) that produces a table showing how each
outlet performed in relation to its weekly revenue goal for each product group. The table should
lists all of the following columns:
i. outlet_id,
ii. week number,
iii. product_group,
iv. actual revenue (for that outlet_id, product_group, and week),
v. revenue goal (for that outlet_id, and product_group),
vi. difference between actual revenue (iv) and revenue goal (v) (in $ amount),
vii. percentage of goal (v) achieved by actual (iv)
*/

create or replace view v_transaction_revenue as (
select
	outlet_id, week_num, product_group, 
    sum(transaction_revenue) as actual_revenue,
    weekly_revenue_goal,
    sum(transaction_revenue)-weekly_revenue_goal as weekly_goal_difference,
    round(sum(transaction_revenue)/weekly_revenue_goal*100,2) as weekly_goal_percentage
from
	(select
		sr.outlet_id,
		ed.week_num,
		p.product_group,
		if(p.product_group='Whole Bean/Teas', t.beanstea_goal,
			if(p.product_group='Beverages', t.beverage_goal,
				if(p.product_group='Food', t.food_goal,
					if(p.product_group='Merchandise', t.merchandise_goal, 0)))) as weekly_revenue_goal,
		if(sr.promo_price_yn='N', sr.quantity*p.current_retail_price, sr.quantity*current_promo_price) as transaction_revenue
	from
		salesreceipts_201904 as sr
		left join products as p
		on sr.product_id=p.id
		left join external_dates as ed
		on sr.transaction_date=ed.date
		left join targets as t
		on sr.outlet_id=t.outlet_id) as temp
where product_group!='Add-Ons'
group by outlet_id, product_group, week_num
);

/*
2. Modify the above queries (or do it again from scratch) to include additional columns, so that the
resulting table contains monthly revenue and target details. The table should contains the following additional columns:
viii. total revenue goal for the outlet in April 2019 for the product_group,
ix. percentage of total revenue goal (viii) achieved by this week’s actual revenue for the
product_group (iv),
x. grand revenue goal for the outlet in April 2019 (ie. regardless of product group),
xi. percentage of grand revenue goal (x) achieved by this week’s actual revenue for the
product_group (iv)
*/

select *,
sum(weekly_revenue_goal) over(partition by outlet_id, product_group) as april_revenue_goal,
round(actual_revenue/sum(weekly_revenue_goal) over(partition by outlet_id, product_group)*100,2) as april_goal_percentage,
sum(weekly_revenue_goal) over(partition by outlet_id) as grand_revenue_goal,
round(actual_revenue/sum(weekly_revenue_goal) over(partition by outlet_id)*100,2) as grand_goal_percentage
from v_transaction_revenue vtr;


/* 
DATA OBJECTIVE: Rather than using multiple tables, we want to bring all the useful data into a single table.
QUERY QUESTION: Using the data from June 2017 to 2020Q1, create a single table (or view) that contains
all the trips up to and including 2020Q1. For each trip, include their stations’ data (for both start and end
stations) and locality data (for both start and end stations). Do not keep any unnecessary, duplicate columns
(eg. there is no need for 2 start_station IDs or 2 start station zip codes, for each row) in this view.
In other words, your table/view should therefore contain the following 22 fields:
For the trip: Start Time, End Time, Bike ID, User Type
For the Start Station: ID, Name, Lat, Long, Year Opened, Zip, City, Region, Sector
For the End Station: ID, Name, Lat, Long, Year Opened, Zip, City, Region, Sector
*/

create or replace view trips_combined as
(select * from trips_2017
union select * from trips_2018
union select * from trips_2019
union select * from trips_2020_q1);

select t.start_time, t.end_time, t.bike_id, t.user_type, 
    t.start_station_id, ss.name ss_name, ss.latitude ss_lat, ss.longitude ss_long, ss.year_open ss_year_open, ss.zip ss_zip,
    sl.city ss_city, sl.region ss_region, sl.sector ss_sector,
    t.end_station_id, es.name es_name, es.latitude es_lat, es.longitude es_long, es.year_open es_year_open, es.zip es_zip,
    el.city es_city, el.region es_region, el.sector es_sector
from 
	trips_combined t
/*ss=start station, es=end station, sl=start locality, el=end locality*/
    inner join stations as ss on t.start_station_id=ss.id
    inner join locality as sl on ss.zip=sl.zip
    inner join stations as es on t.end_station_id=es.id
    inner join locality as el on es.zip=el.zip
