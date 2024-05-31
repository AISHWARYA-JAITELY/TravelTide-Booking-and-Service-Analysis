/*
Question #1:
Calculate the number of flights with a departure time during the work week (Monday through Friday) and the number of flights departing during the weekend (Saturday or Sunday).

Expected column names: working_cnt, weekend_cnt
*/

-- q1 solution:

with temp_table as(
select
	extract (dow from departure_time) as Day_of_dept
from 
	flights)

select
	count(Day_of_dept)filter (where Day_of_dept in (1,2,3,4,5)) as working_cnt,
	count (Day_of_dept) filter (where Day_of_dept in (6, 0)) as weekend_cnt
from 
	temp_table;



/*

Question #2: 
For users that have booked at least 2  trips with a hotel discount, it is possible to calculate their average hotel discount, and maximum hotel discount. write a solution to find users whose maximum hotel discount is strictly greater than the max average discount across all users.

Expected column names: user_id

*/

-- q2 solution:

with temp_table as(
select
	distinct user_id,
	count (distinct trip_id) as tripcount,
	round(avg(hotel_discount_amount),2)as avg_hotel_discount,
	max(hotel_discount_amount)as max_hotel_discount
from
	sessions
where 
	hotel_discount_amount is not null and hotel_discount is true and trip_id is not null
group by 
	1
having 
	(count (trip_id) filter (where trip_id is not null))>1
  )
  
select
	distinct user_id
from 
	temp_table
where 
	max_hotel_discount>(select
                          max(avg_hotel_discount)
                          from temp_table);

/*
Question #3: 
when a customer passes through an airport we count this as one “service”.

for example:

suppose a group of 3 people book a flight from LAX to SFO with return flights. In this case the number of services for each airport is as follows:

3 services when the travelers depart from LAX

3 services when they arrive at SFO

3 services when they depart from SFO

3 services when they arrive home at LAX

for a total of 6 services each for LAX and SFO.

find the airport with the most services.

Expected column names: airport

*/

-- q3 solution:


with temp_table as(
select
	destination_airport as airport,
	sum(case when return_flight_booked = true then seats * 2 else seats end) as services
from 
	flights
where 
	return_flight_booked is true
group by 
	1

union all

select
	origin_airport as airport, 
	sum(case when return_flight_booked = true then seats * 2 else seats end) as services
from 
	flights
where 
	return_flight_booked is true
group by 
	1)


select 
	airport
from 
	temp_table
where 
	services=(select
            	 max(services)
        	 from temp_table);


/*
Question #4: 
using the definition of “services” provided in the previous question, we will now rank airports by total number of services. 

write a solution to report the rank of each airport as a percentage, where the rank as a percentage is computed using the following formula: 

`percent_rank = (airport_rank - 1) * 100 / (the_number_of_airports - 1)`

The percent rank should be rounded to 1 decimal place. airport rank is ascending, such that the airport with the least services is rank 1. If two airports have the same number of services, they also get the same rank.

Return by ascending order of rank

Expected column names: airport, percent_rank**

Expected column names: airport, percent_rank
*/

-- q4 solution:

with airport_services as (

    select 
	  origin_airport as airport,
          sum(case when return_flight_booked = true then seats * 2 else seats end) as services
    from
	 flights
    group by
	 origin_airport, return_flight_booked

    union all

    select destination_airport as airport,
           sum(case when return_flight_booked = true then seats * 2 else seats end) as services
    from 
	flights
    group by 
	destination_airport, return_flight_booked
),

aggregated_services as (

    select 
	airport, sum(services) as total_services
    from 
	airport_services
    group by 
	airport
),

airport_ranks as (

    select 
        airport,
        rank() over (order by total_services asc) as airport_rank,
        count(*) over () as total_airports
    from 
	aggregated_services
)
select 
    airport,
    round((airport_rank - 1) * 100.0 / (total_airports - 1), 1) as percent_rank
from 
    airport_ranks
order by 
    percent_rank asc;
