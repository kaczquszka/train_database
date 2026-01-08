USE train_project;
GO
------------------------------------------------------------------
--testing on delete cascade in carriages in train table

--printing all trains
SELECT * FROM TRAIN;

--adding new train
INSERT INTO TRAIN (date_of_course, delay_in_minutes, route_id, locomotive_id) VALUES
('2025-12-09', 0, 'EIP5100', 8);
SELECT * FROM TRAIN;

--assigning carriage to the train (train_id =11)
INSERT INTO CARRIAGES_IN_TRAIN (train_id, carriage_id, carriage_number, carriage_order)
VALUES (12, 12, 402, 2);
--printing carriages in train
SELECT * FROM CARRIAGES_IN_TRAIN;

--deleting train 
DELETE FROM TRAIN
WHERE train_id = 12

--appropariate carraiegs in train entry is deleteed as well
SELECT * FROM CARRIAGES_IN_TRAIN;

--------------------------------------------------------------------

--CHECKING ON DELETE CASCADE IN ROUTE_PRICING

SELECT * FROM ROUTE;
SELECT * FROM PRICING;
-- adding a new ROUTE entry
INSERT INTO ROUTE (route_id, start_fee, route_name, coursing_from, coursing_until) 
VALUES ('XYZ0001', 1.00, 'Test Cascade Route', '2025-12-01', NULL);

-- assigning an existing pricing to the new route
INSERT INTO ROUTE_PRICING (route_id, pricing_id)
VALUES ('XYZ0001', 1);

-- Printing ROUTE_PRICING 
SELECT * FROM ROUTE_PRICING;

-- DELETING THE NEW ROUTE
DELETE FROM ROUTE
WHERE route_id = 'XYZ0001';

-- Checking ROUTE_PRICING.
SELECT * FROM ROUTE_PRICING;

---------------------------------------------------------------------------
--CHECKING ON UPDATE CASCADE IN ROUTE PRICING/same for route holidays and route weekdays
SELECT * FROM ROUTE;
SELECT * FROM PRICING;
-- adding a new ROUTE entry
INSERT INTO ROUTE (route_id, start_fee, route_name, coursing_from, coursing_until) 
VALUES ('XYZ0001', 1.00, 'Test Cascade Route', '2025-12-01', NULL);

-- assigning an existing pricing to the new route
INSERT INTO ROUTE_PRICING (route_id, pricing_id)
VALUES ('XYZ0001', 1);

-- Printing ROUTE_PRICING 
SELECT * FROM ROUTE_PRICING;

SELECT * FROM ROUTE;

-- UPDATEING ROUTE
UPDATE ROUTE
SET route_id = 'AB1234'
WHERE route_id = 'XYZ0001';

-- Checking ROUTE_PRICING.
SELECT * FROM ROUTE_PRICING;
SELECT * FROM ROUTE;

--------------------------------------------------------------------------------

--deleting tickets deletes the entry from connections as well
SELECT * FROM TICKETS;
SELECT * FROM CONNECTIONS;

INSERT INTO TICKETS (total_price, payment_method, discount_id, users_id) VALUES
(150.50, 'credit card', 3, 1);
SELECT * FROM TICKETS;

INSERT INTO CONNECTIONS (ticket_id, connection_order, price, carriage_id, seat_number, train_id, route_id, starting_order, destination_order) VALUES
(16, 1, 150.50, 1, 1, 1, 'EIP5100', 1, 3)

--new connection established
SELECT * FROM CONNECTIONS;

DELETE FROM TICKETS
WHERE ticket_id = 16;

--connection was deleeted as well
SELECT * FROM CONNECTIONS;



--deleting user does not delete the ticket but sets the user id to NULL
----------------------------------------------------------------------------
SELECT * FROM USERS;

SELECT * FROM TICKETS;

DELETE USERS
WHERE users_id = 2;

SELECT * FROM TICKETS;
----------------------------------------------------------------------------------

--deleting connection deletes pricing-connection
INSERT INTO CONNECTIONS (ticket_id, connection_order, price, carriage_id, seat_number, train_id, route_id, starting_order, destination_order) VALUES
(13, 2, 50.00, 4, 15, 2, 'IC2810', 1, 2);

INSERT INTO PRICING_FOR_CONNECTION(pricing_id, ticket_id, connection_order)
VALUES(1,13,2);

SELECT * FROM CONNECTIONS;
SELECT* FROM PRICING_FOR_CONNECTION;

DELETE CONNECTIONS
WHERE ticket_id = 13 AND connection_order = 2;

SELECT * FROM CONNECTIONS;
SELECT* FROM PRICING_FOR_CONNECTION;