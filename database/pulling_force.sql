USE train_project
GO
/*
1 QUERY
IS THE TOTAL WEIGHT OF THE TRAIN IN BOUNDS OF LCOOMOTIVE PULL CAPACITY?
*/
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

SELECT * FROM LOCOMOTIVES
SELECT * FROM CARRIAGES
SELECT * FROM TRAIN
SELECT * FROM SEATS

SELECT * FROM CARRIAGES_IN_TRAIN
SELECT * FROM vw_total_weight_carriages

SELECT tt.train_id, l.locomotive_id, tt.total_train_weight, l.pulling_weight, (CASE WHEN l.pulling_weight>tt.total_train_weight THEN 'YES' ELSE 'TOO HEAVY!' END) AS in_bounds
FROM vw_total_weight_train AS tt
INNER JOIN LOCOMOTIVES AS l
ON tt.locomotive_id = l.locomotive_id
ORDER BY tt.total_train_weight DESC
