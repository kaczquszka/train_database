USE train_project;
GO

INSERT INTO WEEKDAYS (weekday_name) VALUES
('Monday'),
('Tuesday'),
('Wednesday'),
('Thursday'),
('Friday'),
('Saturday'),
('Sunday');

INSERT INTO ROUTE (route_id, start_fee, route_name, coursing_from, coursing_until) VALUES
('EIP5100', 10.00, 'Pendolino Warszawa-Gdynia', '2023-09-01', NULL),
('IC2810', 5.00, 'Karkonosze', '2024-01-01', '2026-12-31'),
('TLK4301', 3.50, 'Uznam', '2025-06-15', '2026-09-30'),
('IC1703', 7.00, 'Heweliusz', '2023-01-01', NULL),
('EIC3520', 12.00, 'Mickiewicz', '2024-05-01', NULL),
('IC8100', 4.50, 'Wetlina', '2025-03-01', '2026-03-01'),
('EIP6502', 11.50, 'Pendolino Krakow-Wroclaw', '2024-10-01', NULL),
('TLK1805', 2.00, 'Gryf', '2022-01-01', NULL),
('IC9307', 6.00, 'Skierka', '2025-11-01', '2027-11-01'),
('IC2604', 5.50, 'Wielkopolanin', '2023-07-01', NULL);

INSERT INTO STATION (country, city, station_name, address) VALUES
('Poland', 'Warsaw', 'Warszawa Centralna', 'Al. Jerozolimskie 56'),
('Poland', 'Krakow', 'Krakow Glowny', 'Pawia 5'),
('Poland', 'Gdansk', 'Gdansk Glowny', 'Podwale Grodzkie 1'),
('Poland', 'Wroclaw', 'Wroclaw Glowny', 'Pi³sudskiego 105'),
('Poland', 'Katowice', 'Katowice Glowny', 'Plac Marii Sk³odowskiej-Curie 1'),
('Poland', 'Poznan', 'Poznan Glowny', 'Dworcowa 2'),
('Poland', 'Lodz', 'Lodz Fabryczna', 'Jana Kiliñskiego 1'),
('Poland', 'Szczecin', 'Szczecin Glowny', 'Kolejowa 1'),
('Poland', 'Bialystok', 'Bialystok Glowny', 'Kolejowa 7'),
('Poland', 'Lublin', 'Lublin Glowny', 'Plac Dworcowy 1'),
('Poland', 'Rzeszow', 'Rzeszow Glowny', 'Plac Dworcowy 1'),
('Poland', 'Gdynia', 'Gdynia Glowna', 'Plac Konstytucji 1'),
('Poland', 'Koszalin', 'Koszalin Glowny', 'Kolejowa 3'),
('Germany', 'Berlin', 'Berlin Hauptbahnhof', 'Europaplatz 1'),
('Czech Republic', 'Prague', 'Praha Hlavni Nadrazi', 'Wilsonova 8');


INSERT INTO ROUTE_STOPS (route_id, station_id, stop_order, arrival_time, departure_time, km_travelled) VALUES
-- Route 1: EIP5100 
('EIP5100', 3, 1, '06:00', '06:05', 0),    -- Gdansk Glowny
('EIP5100', 7, 2, '08:20', '08:25', 380),  -- Lodz Fabryczna
('EIP5100', 14, 3, '21:45', '21:50', 410), -- kRAKOW gLOWNY

-- Route 2: IC2810 
('IC2810', 4, 1, '10:30', '10:35', 0),    -- Wroclaw Glowny
('IC2810', 10, 2, '12:45', '12:50', 180),  -- Lublin Glowny
('IC2810', 1, 3, '14:00', '14:05', 340),  -- Warszawa Centralna

-- Route 3: TLK4301
('TLK4301', 8, 1, 	'22:00', '22:15', 0),    -- Szczecin Glowny
('TLK4301', 3, 2, 	'00:30', '00:45', 300),  -- Gdansk Glowny
('TLK4301', 1, 3, 	'03:00', '03:10', 550), -- Warszawa Centralna

-- Route 4: IC1703 (Warszawa -> Poznan -> Berlin)
('IC1703', 1, 1, 	'07:30', '07:40', 0),    -- Warszawa Centralna
('IC1703', 6, 2, 	'10:30', '10:40', 300),  -- Poznan Glowny
('IC1703', 14, 3, '13:30', '13:40', 650),  -- Berlin Hauptbahnhof

-- Route 5: EIC3520 (Krakow -> Katowice -> Warsaw)
('EIC3520', 2, 1, 	'15:00', '15:10', 0),    -- Krakow Glowny
('EIC3520', 5, 2, '16:00', '16:10', 80),   -- Katowice Glowny
('EIC3520', 1, 3, '17:30', '17:40', 300),  -- Warszawa Centralna

-- Route 6: IC8100 
('IC8100', 7, 1, '10:00', '10:10', 0),    -- Lodz Fabryczna
('IC8100', 10, 2, '12:30', '12:45', 200),  -- Lublin Glowny
('IC8100', 9, 3, '14:00', '14:10', 450),   -- Bialystok Glowny

-- Route 7: EIP6502 (Krakow -> Katowice -> Wroclaw)
('EIP6502', 2, 1, '14:00', '14:05', 0),    -- Krakow Glowny
('EIP6502', 5, 2, '14:50', '14:55', 80),   -- Katowice Glowny
('EIP6502', 4, 3, '16:45', '16:50', 380),  -- Wroclaw Glowny

-- Route 8: TLK1805 (Szczecin -> Koszalin -> Gdynia)
('TLK1805', 8, 1, '18:00', '18:15', 0),    -- Szczecin Glowny
('TLK1805', 13, 2, '20:10', '20:20', 180), -- Koszalin Glowny
('TLK1805', 12, 3, '22:00', '22:10', 350), -- Gdynia Glowna

-- Route 9: IC9307 (Gdynia -> Gdañsk -> Warszawa)
('IC9307', 12, 1, '09:30', '09:40', 0),    -- Gdynia Glowna
('IC9307', 3, 2, '10:00', '10:10', 30),    -- Gdansk Glowny
('IC9307', 1, 3, '13:30', '13:35', 380),   -- Warszawa Centralna

-- Route 10: IC2604
('IC2604', 3, 1, '07:00', '07:15', 0),     -- Gdansk Glowny
('IC2604', 7, 2, '10:10', '10:20', 200),   -- Lodz Fabryczna
('IC2604', 2, 3, '14:40', '14:50', 490);   -- Krakow Glowny




INSERT INTO LOCOMOTIVES (locomotive_model, company, production_year, pulling_force, max_speed) VALUES
('EP09', 'PKP Intercity', 2000, 380, 160),
('EU07', 'Newag', 1985, 300, 125),
('Husky-500', 'Siemens Mobility', 2018, 450, 200),
('ED161 (Dart)', 'PESA Bydgoszcz', 2016, 320, 160),
('EP08', 'PKP Intercity', 1978, 350, 140),
('E6ACT', 'Newag', 2020, 500, 140),
('EU44 (Husarz)', 'Siemens Mobility', 2010, 480, 230),
('ED250 (Pendolino)', 'Alstom', 2014, 400, 250),
('SM42', 'FabLok', 1975, 200, 90),
('Gama Marathon', 'PESA Bydgoszcz', 2022, 420, 160),
('EP07', 'Newag', 1990, 310, 140),
('Traxx AC3', 'Bombardier', 2019, 470, 200),
('ED74 (Bydgostia)', 'PESA Bydgoszcz', 2007, 250, 160),
('ET41', 'PKP Cargo', 1980, 500, 120),
('EU06', 'English Electric', 1961, 290, 125);

INSERT INTO CARRIAGES (carriage_type, bike_spaces_quantity, contacts, restrooms_quantity, air_conditioning, carriage_weight) VALUES
('Sleeper', 0, 1, 3, 1, 80),
('Commuter', 6, 1, 2, 1, 65),
('Dining', 0, 1, 1, 1, 88),
('Commuter', 10, 0, 2, 0, 60),
('Sleeper', 0, 1, 4, 1, 78),
('Commuter', 4, 1, 1, 1, 55),
('Dining', 0, 1, 1, 1, 92),
('Sleeper', 0, 1, 3, 1, 75),
('Commuter', 0, 0, 1, 0, 70),
('Dining', 0, 1, 2, 1, 90),
('Sleeper', 0, 1, 2, 1, 82),
('Commuter', 8, 1, 2, 1, 62),
('Dining', 0, 0, 1, 0, 85),
('Commuter', 2, 1, 1, 1, 58),
('Sleeper', 0, 1, 3, 1, 79);



INSERT INTO HOLIDAYS (holiday_name, date_of_holiday) VALUES
('New Year Day', '2026-01-01'),
('Epiphany', '2026-01-06'),
('Easter Monday', '2026-04-06'),
('May Day (Labour Day)', '2026-05-01'),
('Constitution Day', '2026-05-03'),
('Corpus Christi', '2026-06-04'),
('Assumption Day', '2026-08-15'),
('All Saints Day', '2026-11-01'),
('Independence Day', '2026-11-11'),
('Christmas Day', '2026-12-25'),
('Second Day of Christmas', '2026-12-26'),
('New Year 2025', '2025-01-01'),
('Epiphany 2025', '2025-01-06'),
('National Education Day', '2026-10-14'),
('Carnival Tuesday', '2026-02-17');


INSERT INTO ROUTE_WEEKDAYS (route_id, weekday_name) VALUES
('EIP5100', 'Monday'), ('EIP5100', 'Wednesday'), ('EIP5100', 'Friday'),
('IC2810', 'Tuesday'), ('IC2810', 'Thursday'), ('IC2810', 'Saturday'),
('TLK4301', 'Friday'), ('TLK4301', 'Sunday'),
('IC1703', 'Monday'), ('IC1703', 'Tuesday'), ('IC1703', 'Wednesday'),
('EIC3520', 'Thursday'),
('IC8100', 'Saturday'),
('EIP6502', 'Sunday'),
('TLK1805', 'Monday'),
('IC9307', 'Tuesday'), 
('IC9307', 'Thursday'),
('IC9307', 'Saturday'),
('IC2604', 'Wednesday'),
('IC2604', 'Friday'),
('IC2604', 'Sunday');

INSERT INTO ROUTE_HOLIDAYS (route_id, holiday_id) VALUES
('EIP5100', 1), ('EIP5100', 10), ('EIP5100', 11),
('IC2810', 3), ('IC2810', 4),
('TLK4301', 5), ('TLK4301', 6),
('IC1703', 7), ('IC1703', 8),
('EIC3520', 9), ('EIC3520', 12),
('IC8100', 2),
('EIP6502', 13),
('TLK1805', 14),
('IC9307', 15);



INSERT INTO PRICING (price_for_km, class, from_km, to_km) VALUES
--TLK
(0.08, 1, 0.00, 5000.00), 
(0.18, 2, 0.00, 5000.00),

--EIP
(0.35, 1, 0.00, 450.00),
(0.25, 2, 0.00, 450.00),
(0.20, 0, 450.01, 5000.00),

--IC 
(0.30, 1, 0.00, 350.00),
(0.20, 2, 0.00, 350.00),
(0.25, 1, 350.01, 800.00),
(0.18, 2, 350.01, 800.00),
(0.15, 0, 800.01, 5000.00),

--EIC
(0.16, 1, 0.00, 50.00), 
(0.13, 0, 0.00, 50.00), 
(0.32, 2, 500.01, 1000.00),

--ONE PRICE
(0.12, 0, 0.00, 3350.00),
(0.20, 1, 0.00, 3350.00),
(0.15, 2, 0.00, 3350.00);


INSERT INTO ROUTE_PRICING (route_id, pricing_id) VALUES
('EIP5100', 3), ('EIP5100', 5), ('EIP5100', 4), 
('IC2810', 6), ('IC2810', 7), ('IC2810', 8), ('IC2810', 9), ('IC2810', 10),
('TLK4301', 1), ('TLK4301', 2),
('IC1703', 14), ('IC1703', 16), ('IC1703', 15), 
('EIC3520', 13), ('EIC3520', 11), ('EIC3520', 12);

INSERT INTO USERS (users_name, users_surname, email, creation_date) VALUES
('Anna', 'Kowalska', 'a.kowalska@trainmail.pl', '2023-11-05'),
('Piotr', 'Nowak', 'pnowak@intercity.com', '2024-03-20'),
('Katarzyna', 'Wozniak', 'kasia.w@railpass.net', '2022-09-10'),
('Adam', 'Zajac', 'adam.zajac@pkp.pl', '2025-01-01'),
('Monika', 'Lis', 'monika_lis@secure.com', '2023-05-15'),
('Michal', 'Jankowski', 'mjankowski@gmail.com', '2024-11-25'),
('Magdalena', 'Krol', 'magda.krol@travel.net', '2022-07-07'),
('Filip', 'Grabowski', 'fgrabowski@fastmail.com', '2025-02-18'),
('Natalia', 'Pietrzak', 'n.pietrzak@outlook.com', '2023-08-30'),
('Robert', 'Lewandowski', 'robert.l@trains.eu', '2024-06-05'),
('Ewa', 'Duda', 'ewa.duda@wp.pl', '2022-10-12'),
('Tomasz', 'Mazur', 'tomasz.mazur@traveler.pl', '2025-03-03'),
('Joanna', 'Wieczorek', 'joanna.w@web.com', '2023-12-09'),
('Pawel', 'Szymanski', 'pawels@rail.pl', '2024-04-15'),
('Weronika', 'Wojcik', 'wwojcik@securemail.pl', '2025-07-22');

INSERT INTO DISCOUNTS (description, name, amount, from_date, to_date) VALUES
('Student discount for full-time students', 'Student', 51.00, '2023-01-01', NULL),
('Senior citizen discount (60+)', 'Senior Citizen', 37.00, '2023-01-01', NULL),
('Early purchase discount (30+ days in advance)', 'Promo Advance', 15.00, '2024-01-01', NULL),
('Weekend Family Travel Promotion', 'Family Weekend', 20.00, '2025-10-01', '2026-03-31'),
('Group discount for 5 or more travelers', 'Group 5+', 10.00, '2024-05-01', NULL),
('Disabled person and guardian discount', 'Disabled/Guardian', 49.00, '2023-01-01', NULL),
('IC Loyalty Card Holder Discount', 'Loyalty Card', 5.00, '2024-01-01', NULL),
('Seasonal Winter Route Special', 'Winter Special', 25.00, '2025-12-01', '2026-02-28'),
('Discount for children up to 16 years old', 'Child', 37.00, '2023-01-01', NULL),
('Last Minute Ticket Sale', 'Last Minute', 50.00, '2025-12-09', '2025-12-10'),
('Discount for military personnel', 'Military', 20.00, '2023-01-01', NULL),
('Intercity Pass Holder Promo', 'IC Pass', 30.00, '2025-01-01', '2025-12-31'),
('Discount for short local routes', 'Local Commuter', 10.00, '2024-01-01', NULL),
('Birthday trip discount (valid in birthday month)', 'Birthday Month', 15.00, '2025-01-01', '2025-12-31');


INSERT INTO TRAIN (date_of_course, delay_in_minutes, route_id, locomotive_id) VALUES
('2025-12-08', 0, 'IC2810', 8), 
('2025-12-09', 15, 'IC2810', 2), 
('2025-12-08', 5, 'TLK4301', 14),
('2025-12-09', 0, 'IC1703', 7), 
('2025-12-08', 45, 'EIC3520', 3), 
('2025-12-08', 0, 'IC8100', 5),
('2025-12-09', 10, 'EIP6502', 8), 
('2025-12-08', 0, 'TLK1805', 1),
('2025-12-08', 2, 'IC9307', 6),
('2025-12-08', 0, 'EIP5100', 8), 
('2025-12-08', 0, 'IC2604', 4);

INSERT INTO CARRIAGES_IN_TRAIN (train_id, carriage_id, carriage_number, carriage_order) VALUES
(1, 1, 1, 1),
(1, 2, 2, 2),
(1, 3, 3, 3),

(2, 4, 101, 1),
(2, 6, 102, 2),

(3, 5, 201, 1),
(3, 7, 202, 2),

(4, 2, 301, 1),
(4, 1, 302, 2),
(4, 3, 303, 3),

(5, 9, 401, 1),
(5, 1, 402, 2),

(6, 10, 501, 1),
(6, 12, 502, 2),
(6, 14, 503, 3),

(7, 1, 601, 1),
(7, 3, 602, 2),
(7, 5, 603, 3),

(8, 2, 701, 1),
(8, 4, 702, 2),

(9, 6, 801, 1),
(9, 8, 802, 2),

(10, 10, 901, 1),
(10, 11, 902, 2);


INSERT INTO SEATS (carriage_id, seat_number, seat_type, window, class) VALUES
(1, 1, 'normal', 1, 2),
(1, 2, 'normal', 0, 2),
(1, 3, 'invalid', 1, 2),
(1, 4, 'normal', 1, 2),
(1, 5, 'normal', 0, 2),
(1, 6, 'normal', 1, 2),
(1, 7, 'normal', 0, 2),
(1, 8, 'invalid', 1, 2),
(1, 9, 'normal', 1, 0),
(1, 10, 'normal', 0, 0),
(1, 11, 'normal', 1, 0),
(1, 12, 'normal', 0, 0),
(1, 13, 'normal', 1, 0),
(1, 14, 'normal', 0, 0),
(1, 15, 'normal', 1, 0),
(1, 16, 'normal', 0, 0),
(2, 1, 'normal', 1, 2),
(2, 2, 'normal', 0, 2),
(2, 3, 'invalid', 1, 2),
(2, 4, 'at the table', 0, 1),
(2, 5, 'elderly people', 1, 0),
(2, 6, 'kids', 0, 0),
(2, 7, 'normal', 0, 0),
(2, 8, 'normal', 0, 0),
(2, 9, 'normal', 1, 0),
(2, 10, 'normal', 0, 0),
(2, 11, 'normal', 1, 0),
(2, 12, 'normal', 0, 0),
(2, 13, 'normal', 1, 0),
(2, 14, 'normal', 0, 0),
(2, 15, 'normal', 1, 0),
(2, 16, 'normal', 0, 0),
(3, 1, 'normal', 1, 0),
(3, 2, 'normal', 1, 0),
(3, 3, 'normal', 1, 0),
(3, 4, 'normal', 1, 0),
(3, 5, 'normal', 0, 0),
(3, 6, 'normal', 0, 0),
(3, 7, 'normal', 0, 0),
(3, 8, 'normal', 0, 0),
(3, 9, 'normal', 1, 0),
(3, 10, 'normal', 0, 0),
(4, 1, 'normal', 1, 0),
(4, 2, 'normal', 0, 0),
(4, 3, 'normal', 1, 0),
(4, 4, 'normal', 0, 0),
(4, 5, 'normal', 1, 0),
(4, 6, 'normal', 0, 0),
(4, 7, 'normal', 0, 0),
(4, 8, 'normal', 0, 0),
(4, 9, 'normal', 1, 0),
(4, 10, 'normal', 0, 0),
(4, 11, 'normal', 1, 0),
(4, 12, 'normal', 0, 0),
(4, 13, 'normal', 1, 0),
(4, 14, 'normal', 0, 0),
(4, 15, 'normal', 1, 0),
(4, 16, 'normal', 0, 0),
(5, 20, 'mother with children', 1, 2),
(5, 21, 'normal', 0, 2),
(5, 22, 'normal', 1, 2),
(6, 1, 'normal', 1, 0),
(6, 2, 'normal', 0, 0),
(7, 1, 'at the table', 1, 1),
(7, 2, 'at the table', 0, 1),
(8, 1, 'normal', 1, 2),
(8, 2, 'invalid', 1, 2),
(9, 1, 'normal', 0, 0),
(9, 2, 'kids', 1, 0),
(10, 1, 'at the table', 1, 1),
(10, 2, 'normal', 0, 1);

INSERT INTO TICKETS (total_price, payment_method, discount_id, users_id) VALUES
(150.50, 'credit card', 3, 1),   -- Promo Advance
(75.00, 'blik', 1, 2),           -- Student Discount (51%)
(250.20, 'google pay', 7, 3),    -- Loyalty Card
(45.99, 'apple pay', 9, 4),       -- Child Discount (37%)
(12.00, 'credit card', 13, 5),   -- Local Commuter
(320.00, 'blik', NULL, 6),       -- No Discount
(88.50, 'google pay', 11, 7),    -- Military
(140.00, 'apple pay', 2, 8),      -- Senior Citizen (37%)
(105.10, 'credit card', 5, 9),    -- Group 5+
(99.99, 'blik', 4, 10),          -- Family Weekend
(50.00, 'credit card', 10, 11),  -- Last Minute Sale (50%)
(180.30, 'google pay', 6, 12),   -- Disabled/Guardian (49%)
(65.00, 'apple pay', 12, 13),    -- IC Pass
(115.00, 'credit card', NULL, 14),
(105.00, 'credit card', NULL, 11),
(115.00, 'credit card', NULL, 8),
(119.99, 'blik', NULL, 2),
(219.99, 'blik', NULL, 4),
(89.99, 'blik', NULL, 1);

INSERT INTO CONNECTIONS (ticket_id, connection_order, price, carriage_id, seat_number, train_id, route_id, starting_order, destination_order) VALUES
(1, 1, 150.50, 1, 1, 1, 'IC2810', 1, 3),  
(2, 1, 75.00, 4, 15, 2, 'IC2810', 1, 3),  
(3, 1, 120.20, 1, 3, 4, 'IC1703', 1, 2),  -- T3: Warszawa -> Poznan
(3, 2, 130.00, 10, 2, 10, 'IC2604', 2, 3),  -- T3: Poznan -> Krakow
(4, 1, 45.99, 6, 1, 2, 'IC2810', 2, 3),  
(5, 1, 12.00, 2, 5, 1, 'IC2810', 2, 3), 
(6, 1, 320.00, 2, 6, 4, 'IC1703', 1, 3), 
(7, 1, 88.50, 3, 10, 1, 'IC2810', 1, 2), 
(8, 1, 140.00, 4, 16, 2, 'IC2810', 1, 2), 
(9, 1, 105.10, 5, 20, 3, 'TLK4301', 1, 3),
(10, 1, 99.99, 1, 1, 4, 'IC1703', 1, 2),
(11, 1, 50.00, 6, 1, 2, 'IC2810', 1, 3),
(12, 1, 180.30, 2, 6, 1, 'IC2810', 1, 3),
(13, 1, 65.00, 4, 1, 2, 'IC2810', 1, 2),
(14, 1, 115.00, 6, 2, 2, 'IC2810', 1, 3),
(15, 1, 119.99, 2, 5, 1, 'IC2810', 1, 3),
(16, 1, 219.99, 4, 3, 2, 'IC2810', 1, 2),
(17, 1, 89.99, 1, 3, 4, 'IC1703', 2, 3);

INSERT INTO PRICING_FOR_CONNECTION (pricing_id, ticket_id, connection_order) VALUES
-- EIP5100, Class 2, 410km
(4, 1, 1),

-- IC2810, Class 0, 340km
(7, 2, 1),

-- IC1703, Class 2, 300km
(15, 3, 1),

-- IC2604, Class 1, 290km
(6, 3, 2),

-- IC2810, Class 0, 160km
(7, 4, 1),

-- EIP5100, Class 0, 30km
(4, 5, 1),

-- IC1703, Class 0, 650km
(14, 6, 1),

-- EIP5100, Class 1, 380km
(3, 7, 1),

-- IC2810, Class 0, 180km
(7, 8, 1),

-- TLK4301, Class 2, 550km
(2, 9, 1),

-- IC1703, Class 2, 300km
(15, 10, 1),

-- IC2810, Class 0, 340km
(7, 11, 1),

-- EIP5100, Class 0, 410km
(4, 12, 1),

-- IC2810, Class 0, 180km
(7, 13, 1),

-- IC1703, Class 2, 350km
(15, 14, 1);