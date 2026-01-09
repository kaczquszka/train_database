USE train_project
GO

/*
4 QUERIES:
GET CONNECTIONS FROM STATION A TO B WITHIN 2 DAYS FROM PROVIDED DATE
1. DIRECT TRAINS
2. EXACTLY ONE CHANGE
3. EXACTLY TWO CHANGES
4. CALCULATE THE TIME OF JOURNEY FROM THE MOMENT OF DEPARTURE FROM STARTING STATION TO THE MOMENT OF ARRIVAL TO THE DESTINATION IN MINUTES

FOURTH QUERY IS CALCULATED WITH FUNCTION 'CALCULATE_TIME' AND IMPLEMENTED IN EACH OF SELECTS FROM THE QUERIES 1-3
*/

-------------------------------------------------HELPER FUNCTIONS------------------------------------------------------
--RETURNS ALL TRAINS THAT RUN AT GIVEN DATE

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
RETURN
(
SELECT *
FROM dbo.ALL_TRAINS(@date) AS t
WHERE (t.stop_order >= (SELECT stop_order FROM ROUTE_STOPS WHERE station_id = @starting_station_id AND route_id = t.route_id))
);

GO

--RETURNS ALL TRAINS TO DESTINATION STATION

CREATE FUNCTION dbo.GET_TRAINS_TO_DESTINATION (@destination_station_id INT, @date DATE)
RETURNS TABLE
AS 
RETURN
(
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
SELECT DATEDIFF(MINUTE,  starting.datetime_departure, destination.datetime_arrival) AS DURATION
FROM dbo.ALL_TRAINS(@date) AS destination
JOIN dbo.ALL_TRAINS(@date) AS starting
ON destination.station_id = @destination_station AND starting.station_id = @starting_station AND destination.train_id = @last_train AND starting.train_ID = @first_train);

GO


----------------------------------------CONNECTION FINDING------------------------------------------------------------------
--RETURNS DIRECT TRAINS
CREATE FUNCTION dbo.DIRECT(@destination_station INT, @date DATE, @starting_station AS INT)
RETURNS TABLE
AS RETURN(
SELECT *, (SELECT * FROM dbo.CALCULATE_TIME(@destination_station,@starting_station, train_id,train_id, @date)) AS DURATION_MINUTES
FROM dbo.GET_TRAINS_FROM_STARTING(@starting_station, @date)  
WHERE station_id = @destination_station);

GO


--ONE SWITCH
CREATE FUNCTION dbo.ONE_SWITCH (@destination_station INT, @date DATE, @starting_station AS INT)
RETURNS TABLE
AS 
RETURN(
SELECT s.train_id AS FIRST_TRAIN, s.station_id AS CHANGE_STATION_ID, s.datetime_arrival, d.train_id AS SECOND_TRAIN, d.datetime_departure, (SELECT * FROM dbo.CALCULATE_TIME(@destination_station,@starting_station, s.train_id,d.train_id, @date)) AS DURATION_MINUTES
FROM dbo.GET_TRAINS_FROM_STARTING(@starting_station, @date) AS s
INNER JOIN dbo.GET_TRAINS_TO_DESTINATION(1, @date) AS d
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
SELECT train_id, route_id, datetime_arrival, DURATION_MINUTES 
FROM dbo.DIRECT(@destination_station_id,@date, @starting_station_id) AS train_details

-----------------------------------------------------------------------------------------------------

--ONE SWITCH
SELECT * FROM dbo.ONE_SWITCH(@destination_station_id,@date, @starting_station_id)

-------------------------------------------------------------------------------------------------------

--TWO SWITCHES
SELECT fst.FIRST_TRAIN, fst.datetime_departure AS DEPARTURE_DATETIME, fst.station_id AS FIRST_CHANGE_STATION, fst.SECOND_TRAIN, snd.station_id AS SECOND_CHANGE_STATION, snd.THIRD_TRAIN, snd.datetime_arrival AS ARRIVAL_DATETIME, (SELECT * FROM CALCULATE_TIME(@destination_station_id, @starting_station_id, fst.FIRST_TRAIN, snd.THIRD_TRAIN, @date)) AS DURATION_MINUTES

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
    FROM dbo.OTHER_TRAINS(@starting_station_id,1,@date) as nd
    INNER JOIN dbo.GET_TRAINS_TO_DESTINATION(1,@date) as rd
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
