USE train_project
GO
/*
1 QUERY
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

SELECT* FROM vw_km_travelled
SELECT * FROM vw_connections_prices

SELECT * FROM CONNECTIONS


SELECT c.train_id, c.route_id, k.total_km, occ.percentage_occupied, SUM(c.total_price) AS total_revenue, (SUM(c.total_price)/k.total_km) AS revenue_per_km
FROM vw_connections_prices AS c
INNER JOIN vw_km_travelled AS k
ON c.route_id = k.route_id
INNER JOIN dbo.all_occupancy_on_route() AS occ
ON c.train_id = occ.train_id
GROUP BY c.train_id,c.route_id, k.total_km , occ.percentage_occupied
ORDER BY TOTAL_REVENUE DESC;