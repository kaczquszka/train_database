USE train_project
GO

CREATE VIEW vw_connection_fees AS
SELECT cf.ticket_id, cf.connection_order, cf.start_fee, pc.pricing_id
FROM (SELECT c.ticket_id, c.train_id, c.route_id, c.connection_order, r.start_fee
FROM CONNECTIONS c
INNER JOIN ROUTE r
ON c.route_id = r.route_id) cf
INNER JOIN PRICING_FOR_CONNECTION pc
ON cf.ticket_id = pc.ticket_id AND cf.connection_order = pc.connection_order

GO

CREATE VIEW vw_all_data AS
SELECT c.ticket_id, c.connection_order, c.price, c.route_id, c.starting_order, c.destination_order, pc.start_fee,pc.price_for_km,pc.from_km,pc.to_km, (nd.km_travelled-st.km_travelled) AS total_km
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

CREATE VIEW vw_sums_connections AS
SELECT vw.ticket_id,vw.connection_order, vw.route_id, vw.start_fee,vw.total_km, t.discount_id, d.amount,(CASE WHEN to_km < total_km THEN (to_km-from_km)*price_for_km WHEN from_km < total_km AND to_km>total_km THEN (total_km-from_km)*price_for_km ELSE 0 END) AS cost_for_km 
FROM vw_all_data vw
INNER JOIN TICKETS t
ON vw.ticket_id = t.ticket_id
INNER JOIN DISCOUNTS d
ON t.discount_id = d.discount_id

GO
/*
SELECT * FROM PRICING_FOR_CONNECTION
SELECT * FROM TICKETS
SELECT * FROM CONNECTIONS
SELECT * FROM DISCOUNTS
SELECT * FROM PRICING
*/
SELECT grouped.ticket_id, SUM(before_discount) AS before_discount, SUM(after_discount) AS after_discount  
FROM (
	SELECT ticket_id, connection_order,start_fee, amount AS discount, SUM(total_km) AS total_km,(SUM(cost_for_km) + start_fee) AS before_discount, (SUM(cost_for_km) + start_fee) *((100-amount)/100) AS after_discount
	FROM vw_sums_connections
	GROUP BY ticket_id, amount,connection_order,start_fee) grouped
GROUP BY grouped.ticket_id



