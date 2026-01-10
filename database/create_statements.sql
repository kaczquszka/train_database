USE train_project;
GO

CREATE TABLE ROUTE(
	route_id VARCHAR(8) NOT NULL
	CHECK (
    route_id LIKE '[A-Z][A-Z][0-9][0-9][0-9][0-9]' 
    OR
    route_id LIKE '[A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9]'
	),
	CHECK ( LEFT(route_id,3) = UPPER(LEFT(route_id,3)) COLLATE Latin1_General_CS_AS ),
	start_fee SMALLMONEY NOT NULL CHECK(start_fee>=0),
	route_name VARCHAR(30),
	CHECK ( LEFT(route_name,1) = UPPER(LEFT(route_name,1)) COLLATE Latin1_General_CS_AS ),
	coursing_from DATE NOT NULL,
	coursing_until DATE,
	CHECK (YEAR(coursing_from) >= 1900),
	CHECK (coursing_until IS NULL OR coursing_from <= coursing_until),
	PRIMARY KEY(route_id)
);

CREATE TABLE LOCOMOTIVES(
	locomotive_id INT IDENTITY PRIMARY KEY,
	locomotive_model VARCHAR(30) NOT NULL,
	company VARCHAR(50) NOT NULL,
	production_year SMALLINT NOT NULL CHECK(production_year BETWEEN 1900 AND 2100),
	pulling_weight INT NOT NULL CHECK(pulling_weight BETWEEN 0 AND 50000),
	max_speed SMALLINT NOT NULL CHECK(max_speed BETWEEN 0 AND 400)
);

CREATE TABLE TRAIN(
	train_id INT IDENTITY PRIMARY KEY,
	date_of_course DATE NOT NULL,
	CHECK (YEAR(date_of_course) >= 1900),
	delay_in_minutes SMALLINT NOT NULL CHECK(delay_in_minutes>=0),
	route_id VARCHAR(8) NOT NULL FOREIGN KEY REFERENCES ROUTE(route_id), --do not allow for changing/deleting route_id after it was assigned to a train
	locomotive_id INT NOT NULL FOREIGN KEY REFERENCES LOCOMOTIVES(locomotive_id) --do not allow deletion if locomotvie assigned to a existing train
);

CREATE TABLE CARRIAGES(
	carriage_id INT IDENTITY PRIMARY KEY,
	carriage_type VARCHAR(8) NOT NULL CHECK (carriage_type IN ('Sleeper', 'Commuter', 'Dining')),
	bike_spaces_quantity TINYINT NOT NULL CHECK (bike_spaces_quantity BETWEEN 0 AND 10),
	contacts BIT NOT NULL,
	restrooms_quantity TINYINT NOT NULL CHECK ( restrooms_quantity BETWEEN 0 AND 20),
	air_conditioning BIT NOT NULL,
	carriage_weight TINYINT NOT NULL CHECK (carriage_weight BETWEEN 0 AND 100)
);

CREATE TABLE CARRIAGES_IN_TRAIN(
	train_id INT NOT NULL FOREIGN KEY REFERENCES TRAIN(train_id) ON DELETE CASCADE, --if train removed from system, relationship is not needed
	carriage_id INT NOT NULL FOREIGN KEY REFERENCES CARRIAGES(carriage_id), -- if carriage was assigned to a train then one cannnot delete the carriage
	carriage_number SMALLINT NOT NULL CONSTRAINT from_1_to_999 CHECK (carriage_number BETWEEN 1 AND 999),
	carriage_order TINYINT NOT NULL CONSTRAINT from_1_to_100 CHECK(carriage_order BETWEEN 1 AND 100),
	PRIMARY KEY(train_id, carriage_id)
);

CREATE TABLE WEEKDAYS(
	weekday_name VARCHAR(9) NOT NULL CONSTRAINT valid_weekday CHECK (weekday_name IN ('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')),
	PRIMARY KEY(weekday_name)
);

CREATE TABLE ROUTE_WEEKDAYS(
	route_id VARCHAR(8) NOT NULL FOREIGN KEY REFERENCES ROUTE(route_id) ON UPDATE CASCADE ON DELETE CASCADE, -- if route was removed, the relationship no longer needed
	weekday_name VARCHAR(9) NOT NULL FOREIGN KEY REFERENCES WEEKDAYS(weekday_name), -- one must not delete weekday entries
	PRIMARY KEY(route_id, weekday_name)
);

CREATE TABLE HOLIDAYS(
	holiday_id INT IDENTITY PRIMARY KEY,
	holiday_name VARCHAR(80),
	date_of_holiday DATE NOT NULL CONSTRAINT from_1900 CHECK(YEAR(date_of_holiday) >=1900)
);

CREATE TABLE ROUTE_HOLIDAYS(
	route_id VARCHAR(8) NOT NULL FOREIGN KEY REFERENCES ROUTE(route_id) ON UPDATE CASCADE ON DELETE CASCADE, -- if route deleted, relationship not neccessary
	holiday_id INT NOT NULL FOREIGN KEY REFERENCES HOLIDAYS(holiday_id) ON DELETE CASCADE, -- if holiday is removed, relationship shouldnt exist eaither
	PRIMARY KEY(route_id, holiday_id)
);
CREATE TABLE STATION(
    station_id INT IDENTITY PRIMARY KEY,
    country VARCHAR(56) NOT NULL 
        CONSTRAINT chk_country_capital CHECK(LEFT(country,1) = UPPER(LEFT(country,1) COLLATE Latin1_General_CS_AS)),
    city VARCHAR(56) NOT NULL 
        CONSTRAINT chk_city_capital CHECK(LEFT(city,1) = UPPER(LEFT(city,1) COLLATE Latin1_General_CS_AS)),
    station_name VARCHAR(40) NOT NULL 
        CONSTRAINT chk_station_name_capital CHECK(LEFT(station_name,1) = UPPER(LEFT(station_name,1) COLLATE Latin1_General_CS_AS)),
    address VARCHAR(120) NOT NULL
);

CREATE TABLE ROUTE_STOPS(
	route_id VARCHAR(8) NOT NULL FOREIGN KEY REFERENCES ROUTE(route_id) ON UPDATE CASCADE ON DELETE CASCADE, --if route deleted, all route stops are deleted as well
	station_id INT NOT NULL FOREIGN KEY REFERENCES STATION(station_id) ON DELETE CASCADE,
	stop_order TINYINT NOT NULL,
	arrival_time VARCHAR(5) NOT NULL 
	CHECK (
           arrival_time LIKE '[0-2][0-9]:[0-5][0-9]'
           AND CAST(LEFT(arrival_time,2) AS INT) BETWEEN 0 AND 23
           AND CAST(RIGHT(arrival_time,2) AS INT) BETWEEN 0 AND 59
    ),
	departure_time VARCHAR(5) NOT NULL CONSTRAINT hour_minute_with_colon
	CHECK (
           departure_time LIKE '[0-2][0-9]:[0-5][0-9]'
           AND CAST(LEFT(departure_time,2) AS INT) BETWEEN 0 AND 23
           AND CAST(RIGHT(departure_time,2) AS INT) BETWEEN 0 AND 59
    ),
	km_travelled SMALLINT NOT NULL CONSTRAINT valid_km_value CHECK(km_travelled >=0),
	CONSTRAINT invalid_km_travelled CHECK((stop_order = 1 AND km_travelled =0 ) OR ((stop_order BETWEEN 2 AND 50) AND km_travelled >0)),
	PRIMARY KEY(route_id, stop_order)
);

CREATE TABLE PRICING (
	pricing_id INT IDENTITY PRIMARY KEY,
	price_for_km SMALLMONEY NOT NULL CHECK (price_for_km BETWEEN 0 AND 100),
	class TINYINT NOT NULL CHECK (class BETWEEN 0 AND 2),
	from_km DECIMAL(6,2) NOT NULL CHECK (from_km BETWEEN 0 AND 5000),
	to_km DECIMAL(6,2) NOT NULL CHECK (to_km BETWEEN 0 AND 5000),
	CONSTRAINT positive_distance CHECK( from_km < to_km)
);

CREATE TABLE ROUTE_PRICING (
	route_id VARCHAR(8) NOT NULL FOREIGN KEY REFERENCES ROUTE(route_id) ON UPDATE CASCADE ON DELETE CASCADE, --if route removed, no need for pricing to be assigned
	pricing_id INT NOT NULL FOREIGN KEY REFERENCES PRICING(pricing_id) ON DELETE CASCADE, -- if pricing removed, delete the relationship as well
	PRIMARY KEY (route_id, pricing_id)
);

CREATE TABLE USERS(
	users_id INT IDENTITY PRIMARY KEY,
	users_name VARCHAR(20) NOT NULL CONSTRAINT chk_name_capital CHECK(LEFT(users_name,1) = UPPER(LEFT(users_name,1) COLLATE Latin1_General_CS_AS)),
	users_surname VARCHAR(20) NOT NULL CONSTRAINT chk_surname_capital CHECK(LEFT(users_surname,1) = UPPER(LEFT(users_surname,1) COLLATE Latin1_General_CS_AS)),
	email VARCHAR(100) NOT NULL,
	creation_date DATE NOT NULL CHECK(YEAR(creation_date)>=1900) 
);

CREATE TABLE DISCOUNTS(
	discount_id INT IDENTITY PRIMARY KEY,
	description VARCHAR(150) NOT NULL,
	name VARCHAR(70) NOT NULL,
	amount DECIMAL(5,2) NOT NULL CONSTRAINT incorrect_percentage CHECK(amount BETWEEN 0 AND 100),
	from_date DATE NOT NULL CHECK(YEAR(from_date)>=1900),
	to_date DATE CHECK(YEAR(to_date)>=1900)
);

CREATE TABLE SEATS(
	carriage_id INT NOT NULL FOREIGN KEY REFERENCES CARRIAGES(carriage_id) ON DELETE CASCADE, 
	--if carriage removed, seats should be removed as well (carriages in train entity will prevent deletion of carriage that has been assigned to any train)
	seat_number TINYINT NOT NULL CHECK(seat_number BETWEEN 1 AND 150),
	seat_type VARCHAR(20) NOT NULL CONSTRAINT invalid_type CHECK(seat_type IN ('normal', 'kids', 'elderly people', 'mother with children', 'at the table', 'invalid')),  
	window BIT NOT NULL,
	class TINYINT NOT NULL CHECK( class BETWEEN 0 AND 2),
	PRIMARY KEY (carriage_id, seat_number)
);
CREATE TABLE TICKETS(
	ticket_id INT IDENTITY PRIMARY KEY,
	total_price DECIMAL(6,2) NOT NULL CONSTRAINT positive_limtied_price CHECK(total_price BETWEEN 0 AND 1000),
	payment_method VARCHAR(20) NOT NULL CONSTRAINT valid_method CHECK( payment_method in ('google pay', 'apple pay', 'blik', 'credit card')),
	discount_id INT FOREIGN KEY REFERENCES DISCOUNTS(discount_id), --discounts should not be removed if added to any tickets, as it could led to data loss needed for analysis
	users_id INT FOREIGN KEY REFERENCES USERS(users_id)ON DELETE SET NULL --users may delete their accounts, in that case the tickets should not be removed as the data is crucial for the company
);

CREATE TABLE CONNECTIONS(
	ticket_id INT NOT NULL FOREIGN KEY REFERENCES TICKETS(ticket_id) ON DELETE CASCADE, --if ticket is deleted from the system (eg. return) the connection must be deleted as well
	connection_order TINYINT NOT NULL CONSTRAINT positive_connection_order CHECK(connection_order BETWEEN 0 AND 20),
	price DECIMAL(5,2) NOT NULL CONSTRAINT positive_limited_price CHECK (price BETWEEN 0 AND 999.99),

	carriage_id INT NOT NULL,
    seat_number TINYINT NOT NULL,
    train_id INT NOT NULL FOREIGN KEY REFERENCES TRAIN(train_id), --train must not be removed if there are connections for it
    route_id VARCHAR(8) NOT NULL,
    starting_order TINYINT NOT NULL,
    destination_order TINYINT NOT NULL,
	CONSTRAINT incorrect_stop_order CHECK(starting_order < destination_order),

	CONSTRAINT seatID FOREIGN KEY (carriage_id, seat_number) REFERENCES SEATS(carriage_id, seat_number), -- seats cannot be removed after connection for them was established
	CONSTRAINT starting_stopID FOREIGN KEY (route_id, starting_order) REFERENCES ROUTE_STOPS(route_id, stop_order), -- satrting_stop cannot be removed if there is a connection from it, the cascade on update could led to circluar cascade
	CONSTRAINT destination_stopID FOREIGN KEY (route_id, destination_order) REFERENCES ROUTE_STOPS(route_id, stop_order), -- destination_stop cannot be removed if there is a connection to it,  the cascade on update could led to circluar cascade

	PRIMARY KEY(ticket_id, connection_order)
);

CREATE TABLE PRICING_FOR_CONNECTION(
	pricing_connection_id INT IDENTITY PRIMARY KEY,
	pricing_id INT NOT NULL FOREIGN KEY REFERENCES PRICING(pricing_id),
	ticket_id INT NOT NULL,
	connection_order TINYINT NOT NULL,
	CONSTRAINT valid_pricing FOREIGN KEY (ticket_id, connection_order) REFERENCES CONNECTIONS(ticket_id, connection_order) ON DELETE CASCADE, 
)