USE train_project
GO

CREATE FUNCTION dbo.GET_TRAINS_FROM_STARTING (@starting_station_id INT, @date DATE)
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
WHERE (DATEDIFF(day, @date,date_of_course) >=0 AND DATEDIFF(day, @date ,date_of_course) <=2 ) AND rs.stop_order >= (SELECT stop_order FROM ROUTE_STOPS WHERE station_id = @starting_station_id AND route_id = t.route_id)
);

GO
CREATE FUNCTION dbo.GET_TRAINS_TO_DESTINATION (@destination_station_id INT, @date DATE)
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
WHERE (DATEDIFF(day, @date,date_of_course) >=0 AND DATEDIFF(day, @date ,date_of_course) <=2 ) AND (rs.stop_order <= (SELECT stop_order FROM ROUTE_STOPS WHERE station_id = @destination_station_id AND route_id = t.route_id))
);
GO



---all trains that do not stop at gdansk and do not stop at warsaw
CREATE FUNCTION dbo.OTHER_TRAINS (@starting_stop INT, @ending_stop INT, @date DATE)
RETURNS TABLE
AS
RETURN(
SELECT t.train_id,t.route_id, t.stop_order, t.station_id, CASE
            WHEN ((t.stop_order > 1) AND (t.arrival_time < (SELECT arrival_time FROM ROUTE_STOPS WHERE (route_id = t.route_id) AND stop_order = 1)))
            THEN (DATEADD(day, 1, CAST(t.date_of_course AS DATETIME))) + CAST(t.arrival_time AS DATETIME)
            ELSE (CAST(t.date_of_course AS DATETIME) + CAST(t.arrival_time AS DATETIME))
        END AS datetime_arrival, CASE
            WHEN ((t.stop_order > 1) AND (t.departure_time < (SELECT departure_time FROM ROUTE_STOPS WHERE (route_id = t.route_id) AND stop_order = 1)))
            THEN (DATEADD(day, 1, CAST(t.date_of_course AS DATETIME))) + CAST(t.departure_time AS DATETIME)
            ELSE (CAST(t.date_of_course AS DATETIME) + CAST(t.departure_time AS DATETIME))
        END AS datetime_departure
FROM ALL_TRAINS_ON_DAY AS t
WHERE t.train_id NOT IN (SELECT train_id FROM dbo.GET_TRAINS_TO_DESTINATION(@ending_stop, @date)) AND t.train_id NOT IN (SELECT train_id FROM dbo.GET_TRAINS_FROM_STARTING(@starting_stop, @date))  
); 
GO

--bezposrednie
CREATE FUNCTION dbo.DIRECT(@destination_station INT, @date DATE, @starting_station AS INT)
RETURNS TABLE
AS RETURN(
SELECT *
FROM dbo.GET_TRAINS_FROM_STARTING(@starting_station, @date)  
WHERE station_id = @destination_station);

GO

--wszystkie z gdanska z jedna przesiadka do warszawy
CREATE FUNCTION dbo.ONE_SWITCH (@destination_station INT, @date DATE, @starting_station AS INT)
RETURNS TABLE
AS 
RETURN(
SELECT s.train_id, s.station_id, s.datetime_arrival, d.train_id AS SECOND_TRAIN, d.datetime_departure
FROM dbo.GET_TRAINS_FROM_STARTING(@starting_station, @date) AS s
INNER JOIN dbo.GET_TRAINS_TO_DESTINATION(1, @date) AS d
ON (s.station_id = d.station_id) AND (s.datetime_arrival < d.datetime_departure) AND (s.train_id <>d.train_id)
WHERE s.train_id NOT IN (SELECT train_id
FROM dbo.GET_TRAINS_FROM_STARTING(@starting_station, @date)  
WHERE station_id = @destination_station) AND d.train_id NOT IN(SELECT train_id
FROM dbo.GET_TRAINS_FROM_STARTING(@starting_station, @date)  
WHERE station_id = @destination_station));

GO

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


/*
--wszystkie do wawy, nie bezposrednie z gdanska
SELECT *
FROM dbo.GET_TRAINS_TO_DESTINATION(@starting_station_id, @date)  
WHERE train_id NOT IN (SELECT train_id 
FROM dbo.GET_TRAINS_FROM_STARTING(@destination_station_id, @date)  
WHERE station_id = @destination_station_id)


SELECT * FROM dbo.GET_TRAINS_FROM_STARTING(@starting_station_id,@date) 
SELECT * FROM OTHER_TRAINS(@starting_station_id,1,@date)*/

SELECT * FROM dbo.DIRECT(@destination_station_id,@date, @starting_station_id)
SELECT * FROM dbo.ONE_SWITCH(@destination_station_id,@date, @starting_station_id)

SELECT fst.FIRST_TRAIN, fst.datetime_departure AS DEPARTURE_DATETIME, fst.station_id AS FIRST_CHANGE, fst.SECOND_TRAIN, snd.station_id, snd.THIRD_TRAIN, snd.datetime_arrival AS ARRIVAL_DATETIME 
FROM( 
SELECT st.datetime_departure, st.station_id, st.train_id AS FIRST_TRAIN, nd.train_id AS SECOND_TRAIN
FROM dbo.GET_TRAINS_FROM_STARTING(@starting_station_id,@date) as st
INNER JOIN dbo.OTHER_TRAINS(@starting_station_id,@destination_station_id,@date) as nd
ON (st.station_id = nd.station_id) 
AND (st.datetime_arrival < nd.datetime_departure) 
AND st.train_id NOT IN (SELECT train_id FROM dbo.ONE_SWITCH(@destination_station_id,@date, @starting_station_id))
AND st.train_id NOT IN (SELECT train_id FROM dbo.DIRECT(@destination_station_id,@date, @starting_station_id))) AS fst

INNER JOIN (
SELECT rd.datetime_arrival, nd.station_id, nd.train_id AS SECOND_TRAIN, rd.train_id AS THIRD_TRAIN
FROM dbo.OTHER_TRAINS(@starting_station_id,1,@date) as nd
INNER JOIN dbo.GET_TRAINS_TO_DESTINATION(1,@date) as rd
ON nd.station_id = rd.station_id
AND (nd.datetime_arrival < rd.datetime_departure)
AND rd.train_id NOT IN (SELECT train_id FROM dbo.DIRECT(@destination_station_id,@date, @starting_station_id))
AND rd.train_id NOT IN (SELECT train_id FROM dbo.ONE_SWITCH(@destination_station_id,@date, @starting_station_id))) AS snd
ON fst.SECOND_TRAIN = snd.SECOND_TRAIN

