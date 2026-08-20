CREATE DATABASE IF NOT EXISTS hotel_analytics;

USE hotel_analytics;

CREATE TABLE hotel_bookings (
    booking_id INT AUTO_INCREMENT PRIMARY KEY,

    hotel VARCHAR(20) NOT NULL,
    is_canceled BOOLEAN NOT NULL,

    lead_time SMALLINT NOT NULL,

    arrival_date_year SMALLINT NOT NULL,
    arrival_date_month VARCHAR(10) NOT NULL,
    arrival_date_week_number TINYINT NOT NULL,
    arrival_date_day_of_month TINYINT NOT NULL,

    stays_in_weekend_nights TINYINT NOT NULL,
    stays_in_week_nights TINYINT NOT NULL,

    num_adults TINYINT NOT NULL,
    num_children TINYINT NOT NULL,
    num_babies TINYINT NOT NULL,

    meal VARCHAR(10) NOT NULL,
    country VARCHAR(10) NOT NULL,

    market_segment VARCHAR(30) NOT NULL,
    distribution_channel VARCHAR(20) NOT NULL,

    is_repeated_guest BOOLEAN NOT NULL,

    previous_cancellations SMALLINT NOT NULL,
    previous_bookings_not_canceled SMALLINT NOT NULL,

    reserved_room_type CHAR(1) NOT NULL,
    assigned_room_type CHAR(1) NOT NULL,

    booking_changes TINYINT NOT NULL,

    deposit_type VARCHAR(20) NOT NULL,

    agent SMALLINT NOT NULL,

    days_in_waiting_list SMALLINT NOT NULL,

    customer_type VARCHAR(20) NOT NULL,

    adr DECIMAL(10,2) NOT NULL,

    required_car_parking_spaces TINYINT NOT NULL,
    total_of_special_requests TINYINT NOT NULL,

    reservation_status VARCHAR(15) NOT NULL,
    reservation_status_date DATE NOT NULL
);


USE hotel_analytics;


-- run this in the command line.
LOAD DATA LOCAL INFILE 'C:/Users/abisk/OneDrive/Desktop/SQL Project/Hotel booking/hotel bookings-cleaned.csv'
INTO TABLE hotel_bookings
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    hotel,
    is_canceled,
    lead_time,
    arrival_date_year,
    arrival_date_month,
    arrival_date_week_number,
    arrival_date_day_of_month,
    stays_in_weekend_nights,
    stays_in_week_nights,
    num_adults,
    num_children,
    num_babies,
    meal,
    country,
    market_segment,
    distribution_channel,
    is_repeated_guest,
    previous_cancellations,
    previous_bookings_not_canceled,
    reserved_room_type,
    assigned_room_type,
    booking_changes,
    deposit_type,
    agent,
    days_in_waiting_list,
    customer_type,
    adr,
    required_car_parking_spaces,
    total_of_special_requests,
    reservation_status,
    reservation_status_date
);


ALTER TABLE hotel_bookings
    ADD COLUMN arrival_date DATE,
    ADD COLUMN total_guests INT,
    ADD COLUMN total_nights INT,
    ADD COLUMN total_revenue DECIMAL(10,2),
    ADD COLUMN room_type_mismatch TINYINT(1);
    
ALTER TABLE hotel_bookings
    ADD COLUMN lead_time_band VARCHAR(20);

-- arrival_date: combine year + month name + day into a real DATE
UPDATE hotel_bookings
SET arrival_date = STR_TO_DATE(
    CONCAT(arrival_date_year, '-', arrival_date_month, '-', arrival_date_day_of_month),
    '%Y-%M-%d'
);

-- total_guests: adults + children + babies
UPDATE hotel_bookings
SET total_guests = num_adults + num_children + num_babies;

-- total_nights: weekend nights + week nights
UPDATE hotel_bookings
SET total_nights = stays_in_weekend_nights + stays_in_week_nights;

-- total_revenue: adr * total_nights
UPDATE hotel_bookings
SET total_revenue = adr * total_nights;

-- room_type_mismatch: 1 if assigned room differs from what was reserved
UPDATE hotel_bookings
SET room_type_mismatch = CASE
    WHEN reserved_room_type <> assigned_room_type THEN 1
    ELSE 0
END;

UPDATE hotel_bookings 
SET 
    lead_time_band = CASE
        WHEN lead_time BETWEEN 0 AND 3 THEN '0-3'
        WHEN lead_time BETWEEN 4 AND 7 THEN '4-7'
        WHEN lead_time BETWEEN 8 AND 14 THEN '8-14'
        WHEN lead_time BETWEEN 15 AND 30 THEN '15-30'
        WHEN lead_time BETWEEN 31 AND 60 THEN '31-60'
        WHEN lead_time BETWEEN 61 AND 90 THEN '61-90'
        WHEN lead_time BETWEEN 91 AND 180 THEN '91-180'
        WHEN lead_time BETWEEN 181 AND 365 THEN '181-365'
        WHEN lead_time >= 366 THEN '366+'
    END;
    
    
ALTER TABLE hotel_bookings MODIFY COLUMN is_canceled SMALLINT;
ALTER TABLE hotel_bookings MODIFY COLUMN is_repeated_guest SMALLINT;
ALTER TABLE hotel_bookings MODIFY COLUMN room_type_mismatch SMALLINT;