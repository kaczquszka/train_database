USE train_project
GO


/*
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
*/

/*
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


SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
*/
---------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION

DECLARE @TargetPricingID INT = ( SELECT TOP 1 pricing_id 
FROM PRICING 
WHERE from_km = 0 
  AND to_km = 400 
  AND class = 1 
  AND price_for_km = 0.2);


IF @TargetPricingID IS NULL
BEGIN
    WAITFOR DELAY '00:00:05';
    INSERT INTO PRICING (price_for_km, class, from_km, to_km)
    VALUES (0.2, 1, 0, 400);
    
    SET @TargetPricingID = SCOPE_IDENTITY();
    PRINT('new pricing added');
    
END



INSERT INTO ROUTE_PRICING (route_id, pricing_id) VALUES
    ('TLK4301', @TargetPricingID)


COMMIT TRANSACTION;

SELECT * FROM ROUTE_PRICING
SELECT * FROM PRICING 

*/
---------------------------------------------------------------------------------------------------------------------------------

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
--SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

BEGIN TRANSACTION;


    DECLARE @NewLocomotive INT = (SELECT TOP 1 locomotive_id
    FROM LOCOMOTIVES
    WHERE  pulling_weight > 5000 AND locomotive_id NOT IN (SELECT locomotive_id FROM TRAIN WHERE date_of_course = '2025-12-09'));


    WAITFOR DELAY '00:00:05';
    IF @NewLocomotive IS NULL 
    BEGIN
        ROLLBACK TRANSACTION;
        PRINT('locomotive not found');
    END
    ELSE
    BEGIN
        UPDATE TRAIN 
        SET locomotive_id = @NewLocomotive,
            delay_in_minutes = 0 
        WHERE train_id = 7;
        PRINT ('Locomotive swapped');
    END
    
COMMIT TRANSACTION;


SELECT * FROM TRAIN WHERE train_id = 7 
