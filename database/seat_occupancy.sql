USE train_project
GO
/*
1 QUERY
returns percentage value of seats that were occupied during total time of journey
*/
/*
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
        SELECT *
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

SELECT *
FROM dbo.all_occupancy_on_route()
ORDER BY percentage_occupied DESC;
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
GROUP BY g.train_id, g.route_id
ORDER BY percentage_occupied DESC;
