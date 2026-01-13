USE train_project
GO

-----------------------------------------------------------------------------------------------------------------------------------------------------
--------------SEAT_OCCUPANCY---------------------------

/*
1 QUERY
GET THE PERCENTAGE OF OCCUPIED SEATS (CALCULATED BY SUMMING TOTAL NUMBER OF OCCUPIED SEATS BETWEEN EACH STOP ON ROUTE)
*/

CREATE VIEW vw_seat_occupancy AS
SELECT g.train_id, g.route_id,CAST((SUM(g.occupancy)*100.0/COUNT(g.occupancy)) AS DECIMAL(5,2)) AS percentage_occupied 
FROM( SELECT t.train_id,t.route_id,  s.carriage_id, s.seat_number, rs.station_id, rs.stop_order, 
(CASE WHEN EXISTS (SELECT * FROM CONNECTIONS
            WHERE (carriage_id = s.carriage_id AND s.seat_number = seat_number) AND (rs.stop_order >=starting_order AND rs.stop_order <= destination_order) AND train_id = t.train_id) THEN 1
            ELSE 0 
            END) AS occupancy
FROM TRAIN AS t
INNER JOIN CARRIAGES_IN_TRAIN AS c
ON( t.train_id = c.train_id)

INNER JOIN SEATS AS s
ON(c.carriage_id = s.carriage_id)

CROSS JOIN ROUTE_STOPS AS rs

WHERE rs.route_id = t.route_id) AS g
GROUP BY g.train_id, g.route_id;

GO

SELECT * FROM vw_seat_occupancy
ORDER BY percentage_occupied DESC;

------------------------------------------------------------------------------------------------------------------------------------------------------


/*
2 QUERY
GET VALUE OF REVENUE FROM TICKETS, CALCUALTE THE REVENUE PER KM TRAVELLED ADD OCCUPANCY FROM PREVIOUSLY CREATED FUNCTION
*/

CREATE VIEW vw_connections_prices AS
SELECT t.ticket_id, t.total_price,c.train_id, c.route_id
FROM CONNECTIONS AS c
INNER JOIN TICKETS AS t
ON c.ticket_id = t.ticket_id;

GO


CREATE VIEW vw_km_travelled AS
SELECT route_id, km_travelled AS total_km
FROM ROUTE_STOPS 
WHERE stop_order = (SELECT MAX(stop_order) FROM ROUTE_STOPS WHERE route_id = route_id);

GO


SELECT c.train_id, c.route_id, k.total_km, occ.percentage_occupied, SUM(c.total_price) AS total_revenue, (SUM(c.total_price)/k.total_km) AS revenue_per_km
FROM vw_connections_prices AS c
INNER JOIN vw_km_travelled AS k
ON c.route_id = k.route_id
INNER JOIN vw_seat_occupancy AS occ
ON c.train_id = occ.train_id
GROUP BY c.train_id,c.route_id, k.total_km , occ.percentage_occupied
ORDER BY TOTAL_REVENUE DESC;

-----------------------------------------------------------------------------------------------------------------------------------------------------------
/*
3 QUERY
IS THE TOTAL WEIGHT OF THE TRAIN IN BOUNDS OF LCOOMOTIVE PULL CAPACITY? (ASSUMING ALL SEATS WILL BE OCCUPIED BY A PERSON WITH AVG WEIGHT ~ 75 KG)
*/

CREATE VIEW vw_total_weight_carriages AS
SELECT c.carriage_id, w.total_passengers_weight, c.carriage_weight, (w.total_passengers_weight + c.carriage_weight) AS total_weight
FROM CARRIAGES AS c
INNER JOIN (
	SELECT carriage_id, COUNT(seat_number)*0.075 AS total_passengers_weight 
	FROM SEATS
	GROUP BY carriage_id) AS w
ON c.carriage_id = w.carriage_id
GROUP BY c.carriage_id, w.total_passengers_weight, c.carriage_weight

GO 

CREATE VIEW vw_total_weight_train AS
SELECT ct.train_id, t.locomotive_id, SUM(tw.total_weight) AS total_train_weight
FROM TRAIN AS t
INNER JOIN CARRIAGES_IN_TRAIN AS ct
ON t.train_id = ct.train_id
INNER JOIN vw_total_weight_carriages AS tw
ON tw.carriage_id = ct.carriage_id
GROUP BY ct.train_id, t.locomotive_id

GO

SELECT tt.train_id, l.locomotive_id, tt.total_train_weight, l.pulling_weight, (CASE WHEN l.pulling_weight>tt.total_train_weight THEN 'YES' ELSE 'TOO HEAVY!' END) AS in_bounds
FROM vw_total_weight_train AS tt
INNER JOIN LOCOMOTIVES AS l
ON tt.locomotive_id = l.locomotive_id
ORDER BY tt.total_train_weight DESC

----------------------------------------------------------------------------------------------------------------------------------------------------
/*
4 QUERY
CALCULATE PRICE FOR TICKET (SUM OF ALL CONNECTION PRICES) INCLUDING DISCOUNT IF ANY
*/
--combine connections with starting fees and all assigned pricing
CREATE VIEW vw_connection_fees AS
SELECT cf.ticket_id, cf.connection_order, cf.start_fee, pc.pricing_id
FROM (SELECT c.ticket_id, c.train_id, c.route_id, c.connection_order, r.start_fee
FROM CONNECTIONS c
INNER JOIN ROUTE r
ON c.route_id = r.route_id) cf
INNER JOIN PRICING_FOR_CONNECTION pc
ON cf.ticket_id = pc.ticket_id AND cf.connection_order = pc.connection_order

GO

--calculate distance travelled during correction
--add information about price for km and interval where price should apply
CREATE VIEW vw_all_data AS
SELECT c.ticket_id, c.connection_order, pc.start_fee,pc.price_for_km,pc.from_km,pc.to_km, (nd.km_travelled-st.km_travelled) AS total_km
FROM CONNECTIONS c
INNER JOIN ROUTE_STOPS st
ON c.route_id = st.route_id AND c.starting_order = st.stop_order 
INNER JOIN ROUTE_STOPS nd
ON c.route_id = nd.route_id AND c.destination_order = nd.stop_order 
INNER JOIN (SELECT cf.ticket_id, cf.connection_order, cf.start_fee, p.pricing_id, price_for_km, from_km, to_km
FROM vw_connection_fees AS cf
INNER JOIN PRICING AS p
ON cf.pricing_id = p.pricing_id) AS pc
ON c.ticket_id = pc.ticket_id AND c.connection_order = pc.connection_order

GO

--sum cost for travelling the km at the price rate
CREATE VIEW vw_sums_connections AS
SELECT vw.ticket_id,vw.connection_order, vw.start_fee,vw.total_km, t.discount_id, d.amount,
(CASE 
WHEN to_km < total_km THEN (to_km-from_km)*price_for_km 
WHEN from_km < total_km AND to_km>total_km THEN (total_km-from_km)*price_for_km ELSE 0 
END) AS cost_for_km 
FROM vw_all_data vw
INNER JOIN TICKETS t
ON vw.ticket_id = t.ticket_id
INNER JOIN DISCOUNTS d
ON t.discount_id = d.discount_id

GO

--sum cost_for_km for all connection for the same ticket, add start_fee only once per connection, apply discount
SELECT grouped.ticket_id, SUM(before_discount) AS before_discount, SUM(after_discount) AS after_discount  
FROM (
	SELECT ticket_id, connection_order,start_fee, amount AS discount, SUM(total_km) AS total_km,(SUM(cost_for_km) + start_fee) AS before_discount, (SUM(cost_for_km) + start_fee) *((100-amount)/100) AS after_discount
	FROM vw_sums_connections
	GROUP BY ticket_id, amount,connection_order,start_fee) grouped
GROUP BY grouped.ticket_id

----------------------------------------------------------------------------------------------------------------------------------------------------

/*
QUERY 5,6,7
FIND CONNECTIONS FROM STATION A TO B (DEFINED IN VARIABLES BELOW)
FIND DIRECT CONNECTIONS
FIND CONNECTIONS WITH ONE SWITCH
FIND CONNECTIONS WITH TWO SWITCHES
*/
CREATE FUNCTION dbo.ALL_TRAINS(@date DATE)
RETURNS TABLE
AS 
RETURN
(
SELECT train_id,t.route_id, rs.stop_order, rs.station_id, CASE
            WHEN ((rs.stop_order > 1) AND (rs.arrival_time < (SELECT arrival_time FROM ROUTE_STOPS WHERE (route_id = t.route_id) AND stop_order = 1)))
            THEN (DATEADD(day, 1, CAST(date_of_course AS DATETIME))) + CAST(rs.arrival_time AS DATETIME)
            ELSE (CAST(date_of_course AS DATETIME) + CAST(rs.arrival_time AS DATETIME))
        END AS datetime_arrival, CASE
            WHEN ((rs.stop_order > 1) AND (rs.departure_time < (SELECT departure_time FROM ROUTE_STOPS WHERE (route_id = t.route_id) AND stop_order = 1)))
            THEN (DATEADD(day, 1, CAST(date_of_course AS DATETIME))) + CAST(rs.departure_time AS DATETIME)
            ELSE (CAST(date_of_course AS DATETIME) + CAST(rs.departure_time AS DATETIME))
        END AS datetime_departure
FROM TRAIN AS t
INNER JOIN ROUTE_STOPS AS rs
ON t.route_id = rs.route_id
WHERE (DATEDIFF(day, @date,date_of_course) >=0 AND DATEDIFF(day, @date ,date_of_course) <=2 )
);

GO

--RETURNS ALL TRAINS FROM STARTING STATION

CREATE FUNCTION dbo.GET_TRAINS_FROM_STARTING (@starting_station_id INT, @date DATE)
RETURNS TABLE
AS 
RETURN(
SELECT *
FROM dbo.ALL_TRAINS(@date) AS t
WHERE (t.stop_order >= (SELECT stop_order FROM ROUTE_STOPS WHERE station_id = @starting_station_id AND route_id = t.route_id))
);

GO

--RETURNS ALL TRAINS TO DESTINATION STATION

CREATE FUNCTION dbo.GET_TRAINS_TO_DESTINATION (@destination_station_id INT, @date DATE)
RETURNS TABLE
AS 
RETURN(
SELECT *
FROM dbo.ALL_TRAINS(@date) AS t
WHERE  (t.stop_order <= (SELECT stop_order FROM ROUTE_STOPS WHERE station_id = @destination_station_id AND route_id = t.route_id))
);

GO

--- RETURNS TRAINS THAT DO NOT STOP AT NEITHER THE DESTINATION NOR THE STARTING STATION
CREATE FUNCTION dbo.OTHER_TRAINS (@starting_stop INT, @ending_stop INT, @date DATE)
RETURNS TABLE
AS
RETURN(
SELECT *
FROM dbo.ALL_TRAINS(@date) AS t
WHERE t.train_id NOT IN (SELECT train_id FROM dbo.GET_TRAINS_TO_DESTINATION(@ending_stop, @date)) AND t.train_id NOT IN (SELECT train_id FROM dbo.GET_TRAINS_FROM_STARTING(@starting_stop, @date))  
); 

GO

--calculate journey duration by providing starting, destination, date and first and last train
CREATE FUNCTION dbo.CALCULATE_TIME(@destination_station INT, @starting_station INT, @first_train INT, @last_train INT, @date DATE)
RETURNS TABLE
AS RETURN (
SELECT DATEDIFF(MINUTE,  starting.datetime_departure, destination.datetime_arrival) AS DURATION, starting.datetime_departure AS DEPARTURE_DATETIME, destination.datetime_departure AS ARRIVAL_DATETIME
FROM dbo.ALL_TRAINS(@date) AS destination
JOIN dbo.ALL_TRAINS(@date) AS starting
ON destination.station_id = @destination_station AND starting.station_id = @starting_station AND destination.train_id = @last_train AND starting.train_ID = @first_train);

GO


----------------------------------------CONNECTION FINDING------------------------------------------------------------------
--RETURNS DIRECT TRAINS
CREATE FUNCTION dbo.DIRECT(@destination_station INT, @date DATE, @starting_station AS INT)
RETURNS TABLE
AS RETURN(
SELECT *, (SELECT DURATION FROM dbo.CALCULATE_TIME(@destination_station,@starting_station, train_id,train_id, @date)) AS DURATION_MINUTES, 
(SELECT DEPARTURE_DATETIME FROM dbo.CALCULATE_TIME(@destination_station,@starting_station, train_id,train_id, @date)) AS DEPARTURE_DATETIME,
(SELECT ARRIVAL_DATETIME FROM dbo.CALCULATE_TIME(@destination_station,@starting_station, train_id,train_id, @date)) AS ARRIVAL_DATETIME
FROM dbo.GET_TRAINS_FROM_STARTING(@starting_station, @date)  
WHERE station_id = @destination_station);

GO


--ONE SWITCH
CREATE FUNCTION dbo.ONE_SWITCH (@destination_station INT, @date DATE, @starting_station AS INT)
RETURNS TABLE
AS 
RETURN(
SELECT s.train_id AS FIRST_TRAIN, s.station_id AS CHANGE_STATION_ID, d.train_id AS SECOND_TRAIN,
(SELECT DURATION FROM dbo.CALCULATE_TIME(@destination_station,@starting_station, s.train_id,d.train_id, @date)) AS DURATION_MINUTES, 
(SELECT DEPARTURE_DATETIME FROM dbo.CALCULATE_TIME(@destination_station,@starting_station, s.train_id,d.train_id, @date)) AS DEPARTURE_DATETIME,
(SELECT ARRIVAL_DATETIME FROM dbo.CALCULATE_TIME(@destination_station,@starting_station, s.train_id,d.train_id, @date)) AS ARRIVAL_DATETIME

FROM dbo.GET_TRAINS_FROM_STARTING(@starting_station, @date) AS s
INNER JOIN dbo.GET_TRAINS_TO_DESTINATION(@destination_station, @date) AS d
ON (s.station_id = d.station_id) AND (s.datetime_arrival < d.datetime_departure) AND (s.train_id <>d.train_id)
WHERE s.train_id NOT IN (SELECT train_id
FROM dbo.GET_TRAINS_FROM_STARTING(@starting_station, @date)  
WHERE station_id = @destination_station) AND d.train_id NOT IN(SELECT train_id
FROM dbo.GET_TRAINS_FROM_STARTING(@starting_station, @date)  
WHERE station_id = @destination_station));

GO


----------------------- RESULTS --------------------------------

--VARIABLES
DECLARE @starting_station_id AS INT;
DECLARE @destination_station_id AS INT;
DECLARE @date AS DATE;

SET @date = '2025-12-08';

SELECT @starting_station_id = station_id
FROM STATION
WHERE station_name = 'Gdansk Glowny';

SELECT @destination_station_id = station_id
FROM STATION
WHERE station_name = 'Warszawa Centralna';


--------------------------------------------------------------------------------------------------

--DIRECT
SELECT train_id, route_id, DURATION_MINUTES, DEPARTURE_DATETIME, ARRIVAL_DATETIME
FROM dbo.DIRECT(@destination_station_id,@date, @starting_station_id) AS train_details

-----------------------------------------------------------------------------------------------------

--ONE SWITCH
SELECT * FROM dbo.ONE_SWITCH(@destination_station_id,@date, @starting_station_id)

-------------------------------------------------------------------------------------------------------

--TWO SWITCHES
SELECT fst.FIRST_TRAIN, fst.station_id AS FIRST_CHANGE_STATION, fst.SECOND_TRAIN, snd.station_id AS SECOND_CHANGE_STATION, 
snd.THIRD_TRAIN,
(SELECT DURATION FROM CALCULATE_TIME(@destination_station_id, @starting_station_id, fst.FIRST_TRAIN, snd.THIRD_TRAIN, @date)) AS DURATION_MINUTES,
(SELECT DEPARTURE_DATETIME FROM dbo.CALCULATE_TIME(@destination_station_id,@starting_station_id, fst.FIRST_TRAIN, snd.THIRD_TRAIN, @date)) AS DEPARTURE_DATETIME,
(SELECT ARRIVAL_DATETIME FROM dbo.CALCULATE_TIME(@destination_station_id,@starting_station_id, fst.FIRST_TRAIN, snd.THIRD_TRAIN, @date)) AS ARRIVAL_DATETIME


--joining first and second train
FROM( 
    SELECT st.datetime_departure, st.station_id, st.train_id AS FIRST_TRAIN, nd.train_id AS SECOND_TRAIN
    FROM dbo.GET_TRAINS_FROM_STARTING(@starting_station_id,@date) as st
    INNER JOIN dbo.OTHER_TRAINS(@starting_station_id,@destination_station_id,@date) as nd
    ON (st.station_id = nd.station_id) 
    AND (st.datetime_arrival < nd.datetime_departure) 
    AND NOT EXISTS(
        SELECT 1 
        FROM dbo.ONE_SWITCH(@destination_station_id,@date, @starting_station_id) os 
        WHERE st.train_id = os.SECOND_TRAIN OR st.train_id = os.FIRST_TRAIN)
    AND st.train_id NOT IN (SELECT train_id FROM dbo.DIRECT(@destination_station_id,@date, @starting_station_id))) AS fst

--joining second with the third
INNER JOIN (
    SELECT rd.datetime_arrival, nd.station_id, nd.train_id AS SECOND_TRAIN, rd.train_id AS THIRD_TRAIN
    FROM dbo.OTHER_TRAINS(@starting_station_id,@destination_station_id,@date) as nd
    INNER JOIN dbo.GET_TRAINS_TO_DESTINATION(@destination_station_id,@date) as rd
    ON nd.station_id = rd.station_id
    AND (nd.datetime_arrival < rd.datetime_departure)
    AND rd.train_id NOT IN (SELECT train_id FROM dbo.DIRECT(@destination_station_id,@date, @starting_station_id))
    AND NOT EXISTS(
        SELECT 1 
        FROM dbo.ONE_SWITCH(@destination_station_id,@date, @starting_station_id) os 
        WHERE rd.train_id = os.SECOND_TRAIN OR rd.train_id = os.FIRST_TRAIN)) AS snd

--joing two tables together on the same second train
ON fst.SECOND_TRAIN = snd.SECOND_TRAIN

-------------------------------------------------------------------------------------------------------------------------------------------------------
/*
QUERY 8
RETURN ALL AVAILABLE SEATS FOR CONNECTION FOR CHOSEN CLASS
*/

CREATE FUNCTION occupancy_on_connection(@destination_station_id INT, @train_id INT, @starting_station_id INT) 
RETURNS TABLE
AS
RETURN(
SELECT g.train_id,g.route_id, g.carriage_id, g.seat_number, SUM(g.occupancy) AS occupancy 
FROM(
    SELECT t.train_id,t.route_id, rs.stop_order, s.carriage_id, s.seat_number,
    (CASE WHEN EXISTS (SELECT * FROM CONNECTIONS
                WHERE (carriage_id = s.carriage_id AND s.seat_number = seat_number) AND (rs.stop_order >=starting_order AND rs.stop_order <= destination_order) AND train_id = t.train_id) THEN 1
                ELSE 0 
                END) AS occupancy
    FROM TRAIN AS t
    INNER JOIN CARRIAGES_IN_TRAIN AS c
    ON( t.train_id = c.train_id AND t.train_id = @train_id)
    INNER JOIN SEATS AS s
    ON(c.carriage_id = s.carriage_id)
    CROSS JOIN ROUTE_STOPS AS rs
    WHERE rs.route_id = t.route_id 
    AND rs.stop_order >= (SELECT stop_order FROM ROUTE_STOPS WHERE route_id = t.route_id AND station_id = @starting_station_id) 
    AND rs.stop_order <= (SELECT stop_order FROM ROUTE_STOPS WHERE route_id = t.route_id AND station_id = @destination_station_id)
    ) AS g
GROUP BY g.train_id,g.route_id, g.carriage_id, g.seat_number
);

GO

DECLARE @starting_station_id AS INT;
DECLARE @destination_station_id AS INT;
DECLARE @date AS DATE;
DECLARE @route_id AS VARCHAR(8);
DECLARE @train_id AS INT;
DECLARE @class AS TINYINT;

SET @date = '2025-12-08';
SET @route_id = 'IC2810';
SET @class = 2;

SELECT @starting_station_id = station_id
FROM STATION
WHERE station_name = 'Wroclaw Glowny';

SELECT @destination_station_id = station_id
FROM STATION
WHERE station_name = 'Warszawa Centralna';


SELECT @train_id=train_id FROM TRAIN
WHERE date_of_course = @date AND route_id = @route_id;


SELECT vw.train_id, vw.route_id, vw.carriage_id,vw.seat_number, s.seat_type, s.window, s.class
FROM occupancy_on_connection(@destination_station_id, @train_id, @starting_station_id) AS vw
INNER JOIN SEATS AS s
ON s.carriage_id = vw.carriage_id AND s.seat_number = vw.seat_number
WHERE occupancy = 0 AND s.class = @class;