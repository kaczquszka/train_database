USE train_project
GO


-- NO ISOLATION
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;

INSERT INTO TICKETS (total_price, payment_method, discount_id, users_id) 
VALUES (150.50, 'credit card', 3, 1);

DECLARE @NewTicketID INT = SCOPE_IDENTITY();
    
IF NOT EXISTS (
    SELECT * FROM CONNECTIONS 
    WHERE seat_number = 5 AND carriage_id = 1 AND train_id = 1
)

BEGIN
    WAITFOR DELAY '00:00:05';
    INSERT INTO CONNECTIONS (ticket_id, connection_order, price, carriage_id, seat_number, train_id, route_id, starting_order, destination_order) 
    VALUES (@NewTicketID, 1, 150.50, 1, 5, 1, 'IC2810', 1, 3);
    INSERT INTO PRICING_FOR_CONNECTION (pricing_id, ticket_id, connection_order) VALUES
    (4, @NewTicketID, 1);
    COMMIT TRANSACTION;
END
ELSE
    BEGIN
    ROLLBACK TRANSACTION;
    PRINT('rolled back');
    END
   

SELECT * FROM CONNECTIONS WHERE seat_number = 5 AND carriage_id =1 AND train_id = 1
SELECT* FROM TICKETS

/*
BEGIN TRANSACTION;

INSERT INTO ROUTE (route_id, start_fee, route_name, coursing_from, coursing_until) VALUES
('TST5100', 10.00, 'Testing', '2023-09-01', NULL);

INSERT INTO ROUTE_STOPS (route_id, station_id, stop_order, arrival_time, departure_time, km_travelled) VALUES
-- Route 1: EIP5100
('TST5100', 3, 1, '06:00', '06:05', 0),    
('TST5100', 7, 2, '08:20', '08:25', 380),  
('TST5100', 14, 3, '21:45', '21:50', 410);

COMMIT TRANSACTION;

----------------------------------------------------------------------------------------------------------------------------------

BEGIN TRANSACTION;

INSERT INTO CARRIAGES (carriage_type, bike_spaces_quantity, contacts, restrooms_quantity, air_conditioning, carriage_weight) VALUES
('Sleeper', 0, 1, 3, 1, 80);

DECLARE @NewCarriageID INT = SCOPE_IDENTITY();

INSERT INTO SEATS (carriage_id, seat_number, seat_type, window, class) VALUES
(@NewCarriageID, 1, 'normal', 1, 2),
(@NewCarriageID, 2, 'normal', 0, 2),
(@NewCarriageID, 3, 'normal', 1, 2),
(@NewCarriageID, 4, 'normal', 0, 2);

COMMIT TRANSACTION;

SELECT * FROM CARRIAGES */