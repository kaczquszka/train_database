USE train_project;
GO


SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

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
        WHERE train_id = 2;
        PRINT ('Locomotive swapped');
    END
    
COMMIT TRANSACTION;


SELECT * FROM TRAIN WHERE train_id = 2

--without isolation another user assigned the same locomotive for another train for the same date