USE train_project
GO

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
WHERE occupancy = 0 AND s.class = @class