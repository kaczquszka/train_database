USE train_project
GO
------------------------------------------------------------------------------------

--TICKETS SOLD + PERCENTAGE OCCUPIED

SELECT c.train_id, c.route_id, k.total_km, occ.percentage_occupied, SUM(c.total_price) AS total_revenue, (SUM(c.total_price)/k.total_km) AS revenue_per_km
FROM vw_connections_prices AS c
INNER JOIN vw_km_travelled AS k
ON c.route_id = k.route_id
INNER JOIN dbo.all_occupancy_on_route() AS occ
ON c.train_id = occ.train_id
GROUP BY c.train_id,c.route_id, k.total_km , occ.percentage_occupied
ORDER BY TOTAL_REVENUE DESC;

------------------------------------------------------------------------------------

--PERCENTAGE OCCUPIED

SELECT *
FROM dbo.all_occupancy_on_route()
ORDER BY percentage_occupied DESC;

-------------------------------------------------------------------------------------

--PULLING FORCE

SELECT tt.train_id, l.locomotive_id, tt.total_train_weight, l.pulling_weight, (CASE WHEN l.pulling_weight>tt.total_train_weight THEN 'YES' ELSE 'TOO HEAVY!' END) AS in_bounds
FROM vw_total_weight_train AS tt
INNER JOIN LOCOMOTIVES AS l
ON tt.locomotive_id = l.locomotive_id
ORDER BY tt.total_train_weight DESC

--------------------------------------------------------------------------------------------

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



