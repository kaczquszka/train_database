USE train_project
GO
CREATE FUNCTION dbo.all_occupancy_on_route()
RETURNS @result TABLE(
	train_id INT,
	percentage_occupied DECIMAL(5,2)
	)
AS
BEGIN 
    
	DECLARE @SEAT_OCCUPANCY TABLE(
	id INT IDENTITY PRIMARY KEY,
	carriage_id INT NOT NULL,
    seat_number TINYINT NOT NULL,
    stop_order TINYINT NOT NULL,
    train_id INT NOT NULL,
	occupied SMALLINT NOT NULL CHECK (occupied BETWEEN 0 AND 1 )
    );

    INSERT INTO @SEAT_OCCUPANCY (
        carriage_id,
        seat_number,
        stop_order,
        train_id,
        occupied
    )
    SELECT
        c.carriage_id,
        s.seat_number,
        rs.stop_order,
        t.train_id,
        CASE
            WHEN EXISTS (SELECT *
            FROM CONNECTIONS
            WHERE (carriage_id = c.carriage_id AND s.seat_number = seat_number)
            AND (rs.stop_order >=starting_order AND rs.stop_order <= destination_order) AND train_id = t.train_id) THEN 1
            ELSE 0
        END
    FROM TRAIN AS t
    INNER JOIN CARRIAGES_IN_TRAIN AS c
    ON( t.train_id = c.train_id)

    INNER JOIN SEATS AS s
    ON(c.carriage_id = s.carriage_id)

    CROSS JOIN ROUTE_STOPS AS rs

    WHERE rs.route_id = t.route_id;

    INSERT INTO @result
    SELECT train_id, CAST(
    ROUND(SUM(CAST(occupied AS DECIMAL(10,2))) * 100.0 / COUNT(*), 2)
    AS DECIMAL(5,2)
    )
    FROM @SEAT_OCCUPANCY
    GROUP BY train_id;
    
    RETURN;
END;

GO

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

CREATE VIEW vw_total_weight_carriages AS
SELECT c.carriage_id, w.total_passengers_weight, c.carriage_weight, (w.total_passengers_weight + c.carriage_weight) AS total_weight
FROM CARRIAGES AS c
INNER JOIN (
	SELECT carriage_id, COUNT(seat_number)*75 AS total_passengers_weight 
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
