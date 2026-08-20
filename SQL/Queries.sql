USE hotel_analytics;

-- Overview
-- Total bookings, cancellation rate, and revenue by hotel type.
WITH summary_cte AS(
	SELECT 
		hotel,
		COUNT(*) AS total_bookings_received,
		COUNT(CASE
			WHEN is_canceled = 0 THEN booking_id
		END) AS confirmed_bookings,
		COUNT(CASE
			WHEN is_canceled = 1 THEN booking_id
		END) AS cancelations,
		SUM(CASE
			WHEN is_canceled = 0 THEN total_revenue
		END) AS revenue
	FROM
		hotel_bookings
	GROUP BY hotel
)
SELECT 
	hotel,
    total_bookings_received,
    confirmed_bookings,
    cancelations,
    ROUND(100 * cancelations / total_bookings_received, 2) AS cancelation_rate,
    revenue
FROM
    summary_cte;
    
    
-- Booking trend over the 3 years (2015–2017) — growth, seasonality.
SELECT 
    MONTH(arrival_date) AS calendar_month,
    COUNT(booking_id) AS confirmed_bookings,
    SUM(total_revenue) AS total_revenue
FROM
    hotel_bookings
WHERE
    is_canceled = 0
GROUP BY calendar_month
ORDER BY calendar_month;

SELECT 
    DATE_FORMAT(arrival_date, '%Y-%m') AS 'year_month',
    COUNT(booking_id) AS confirmed_bookings,
    SUM(total_revenue) AS total_revenue
FROM
    hotel_bookings
WHERE
    is_canceled = 0
GROUP BY `year_month`
ORDER BY `year_month`;


-- Cancellation Analysis:
-- Cancellation rate by deposit type (this is the standout finding — worth a dedicated question).
SELECT 
    deposit_type,
    COUNT(*) AS total_bookings_received,
    COUNT(CASE
        WHEN is_canceled = 1 THEN booking_id
    END) AS cancelations,
    SUM(CASE
        WHEN is_canceled = 1 THEN total_revenue
    END) AS opportunity_cost,
    ROUND(100 * COUNT(CASE
                WHEN is_canceled = 1 THEN booking_id
            END) / COUNT(*),
            2) AS cancelation_rate
FROM
    hotel_bookings
GROUP BY deposit_type;
-- Non-Refund bookings cancel 94.70% of the time, 
-- vs. 26.72% for No Deposit and 24.30% for Refundable

-- Checking whether Non-Refund bookings cluster heavily in one market_segment, 
-- distribution_channel, or agent.
SELECT 
    market_segment,
    distribution_channel,
    agent,
    COUNT(booking_id) AS cancellations
FROM
    hotel_bookings
WHERE
    deposit_type = 'Non Refund'
        AND is_canceled = 1
GROUP BY market_segment , distribution_channel , agent
ORDER BY cancellations DESC;
--  Agent 1 has nearly one third of non-refund canncellations, specifically groups under TA/TO channel.

-- Investigating all cancellations from Agent 1.
SELECT 
    market_segment,
    distribution_channel,
    COUNT(*) AS total_bookings_received,
    COUNT(CASE
        WHEN is_canceled = 1 THEN booking_id
    END) AS cancelations,
    ROUND(100 * COUNT(CASE
                WHEN is_canceled = 1 THEN booking_id
            END) / COUNT(*),
            2) AS cancelation_rate
FROM
    hotel_bookings
WHERE
    agent = 1
GROUP BY market_segment , distribution_channel;


-- Cancellation rate by lead time band.
SELECT 
    lead_time_band,
    COUNT(*) AS total_bookings_received,
    COUNT(CASE
        WHEN is_canceled = 1 THEN booking_id
    END) AS cancelations,
    ROUND(100 * COUNT(CASE
                WHEN is_canceled = 1 THEN booking_id
            END) / COUNT(*),
            2) AS cancelation_rate
FROM
    hotel_bookings
GROUP BY lead_time_band
ORDER BY cancelation_rate DESC;


-- Cancellation rate by market segment and distribution channel.
SELECT 
    market_segment,
    distribution_channel,
    COUNT(*) AS total_bookings_received,
    COUNT(CASE
        WHEN is_canceled = 1 THEN booking_id
    END) AS cancelations,
    ROUND(100 * COUNT(CASE
                WHEN is_canceled = 1 THEN booking_id
            END) / COUNT(*),
            2) AS cancelation_rate
FROM
    hotel_bookings
GROUP BY market_segment , distribution_channel
HAVING total_bookings_received >= 10
ORDER BY cancelation_rate DESC;
-- Avoiding channels that have less then 10 bookings received to avoid sample noise.


-- Previous cancellation history.
SELECT 
    CASE
        WHEN previous_cancellations = 0 THEN '0'
        WHEN previous_cancellations = 1 THEN '1'
        WHEN previous_cancellations = 2 THEN '2'
        WHEN previous_cancellations = 3 THEN '3'
        WHEN previous_cancellations = 4 THEN '4'
        WHEN previous_cancellations = 5 THEN '5'
        ELSE '6+'
    END AS previous_cancellations_binned,
    COUNT(*) AS total_bookings_received,
    COUNT(CASE
        WHEN is_canceled = 1 THEN booking_id
    END) AS cancelations,
    ROUND(100 * COUNT(CASE
                WHEN is_canceled = 1 THEN booking_id
            END) / COUNT(*),
            2) AS cancelation_rate
FROM
    hotel_bookings
GROUP BY previous_cancellations_binned
ORDER BY previous_cancellations_binned;


-- Cancellations by customer type.
SELECT 
    customer_type,
    COUNT(*) AS total_bookings_received,
    COUNT(CASE
        WHEN is_canceled = 1 THEN booking_id
    END) AS cancellations,
    ROUND(100 * COUNT(CASE
                WHEN is_canceled = 1 THEN booking_id
            END) / COUNT(*),
            2) AS cancellation_rate
FROM
    hotel_bookings
GROUP BY customer_type
ORDER BY customer_type;


-- Revenue Analysis:
-- Average ADR by hotel type, room type, and month.
SELECT 
    hotel,
    assigned_room_type,
    MONTH(arrival_date) AS arrival_month,
    AVG(CASE
        WHEN is_canceled = 0 THEN adr
    END) AS avg_adr
FROM
    hotel_bookings
GROUP BY hotel , assigned_room_type , arrival_month
ORDER BY avg_adr DESC;


-- Revenue lost to cancellations (ADR × canceled nights).
SELECT 
    hotel,
    SUM(total_revenue) AS total_potential_revenue,
    SUM(CASE
        WHEN is_canceled = 1 THEN total_revenue
    END) AS revenue_at_risk_from_cancellations,
    ROUND(100 * SUM(CASE
                WHEN is_canceled = 1 THEN total_revenue
            END) / SUM(total_revenue),
            2) AS cancelled_percent
FROM
    hotel_bookings
GROUP BY hotel;


-- Does lead time correlate with ADR (do early bookers pay less/more)?
SELECT 
    (AVG(lead_time * adr) - AVG(lead_time) * AVG(adr)) / (STDDEV_POP(lead_time) * STDDEV_POP(adr)) AS correlation_coefficient
FROM
    hotel_bookings
WHERE
    is_canceled = 0;
    
    
-- ADR trend over time (flagged earlier — bookings flat/down but revenue rising 2016→2017)
SELECT 
    DATE_FORMAT(arrival_date, '%Y-%m') AS 'year_month',
    ROUND(AVG(CASE
                WHEN is_canceled = 0 THEN adr
            END),
            2) AS avg_adr
FROM
    hotel_bookings
GROUP BY `year_month`
ORDER BY `year_month`;


-- Guest Geography:
-- Top 10 countries by booking volume and by cancellation rate.
SELECT 
    country,
    COUNT(*) AS total_bookings_received,
    COUNT(CASE
        WHEN is_canceled = 0 THEN booking_id
    END) AS confirmed_bookings,
    COUNT(CASE
        WHEN is_canceled = 1 THEN booking_id
    END) AS cancellations,
    ROUND(100 * COUNT(CASE
                WHEN is_canceled = 1 THEN booking_id
            END) / COUNT(*),
            2) AS cancellation_rate
FROM
    hotel_bookings
GROUP BY country
ORDER BY total_bookings_received DESC , cancellation_rate DESC
LIMIT 10;


-- Party size (total_guests) by market segment.
SELECT 
    market_segment,
    CASE
        WHEN total_guests BETWEEN 1 AND 5 THEN '1-5'
        WHEN total_guests BETWEEN 6 AND 15 THEN '6-15'
        WHEN total_guests BETWEEN 16 AND 30 THEN '16-30'
        ELSE '31+'
    END AS party_size,
    COUNT(*) AS total_bookings_received,
    COUNT(CASE
        WHEN is_canceled = 0 THEN booking_id
    END) AS confirmed_bookings,
    ROUND(100 * COUNT(CASE
                WHEN is_canceled = 0 THEN booking_id
            END) / COUNT(*),
            2) AS confirmation_rate
FROM
    hotel_bookings
GROUP BY market_segment , party_size
HAVING total_bookings_received >= 10
ORDER BY confirmation_rate DESC;
-- Dropping segments that have less then 10 bookings received to avoid sample noise.


-- Top countries by confirmed revenue.
SELECT 
    country,
    SUM(CASE
        WHEN is_canceled = 0 THEN total_revenue
    END) AS total_confirmed_revenue
FROM
    hotel_bookings
GROUP BY country
ORDER BY total_confirmed_revenue DESC
LIMIT 10;


-- Stay Patterns & Room Assignment:
-- Average length of stay (total_nights) by hotel type and segment.
SELECT 
    hotel,
    market_segment,
    ROUND(IFNULL(AVG(CASE
                        WHEN is_canceled = 0 THEN total_nights
                    END),
                    0),
            2) AS avg_length_of_stay
FROM
    hotel_bookings
GROUP BY hotel , market_segment;


-- Room type mismatch (room_type_mismatch) rate, 
-- and whether it correlates with cancellation or special requests.
	SELECT 
    COUNT(*) AS total_bookings_received,
    COUNT(CASE
        WHEN room_type_mismatch = 1 THEN booking_id
    END) AS bookings_with_room_mismatch,
    ROUND(100 * COUNT(CASE
                WHEN room_type_mismatch = 1 THEN booking_id
            END) / COUNT(*),
            2) room_mismatch_rate,
    COUNT(CASE
        WHEN is_canceled = 1 THEN booking_id
    END) AS cancellations,
    ROUND(100 * COUNT(CASE
                WHEN is_canceled = 1 THEN booking_id
            END) / COUNT(*),
            2) AS cancellation_rate
FROM
    hotel_bookings;
    
    
-- CORRECTED: row-level correlation (previously computed on daily-aggregated rates, which inflated the coefficient to -0.60)
SELECT 
    (AVG(room_type_mismatch * is_canceled) - AVG(room_type_mismatch) * AVG(is_canceled)) / (STDDEV_POP(room_type_mismatch) * STDDEV_POP(is_canceled)) AS correlation_coefficient
FROM
    hotel_bookings;
-- Row-level correlation is -0.21 (moderate negative), not -0.60. 
-- Mismatch still associates with lower cancellation, but less dramatically than the aggregated version suggested.
-- One possible explanation: hotel handles mismatch by upgrading room type for guests who show up.


-- Repeat Guests & Loyalty:
-- Cancellation rate: repeat guests vs. new guests.
SELECT 
    CASE
        WHEN is_repeated_guest = 1 THEN 'repeat_guests'
        ELSE 'new_guests'
    END AS guest_type,
    COUNT(*) AS total_bookings_received,
    COUNT(CASE
        WHEN is_canceled = 1 THEN booking_id
    END) AS cancellations,
    ROUND(100 * COUNT(CASE
                WHEN is_canceled = 1 THEN booking_id
            END) / COUNT(*),
            2) AS cancellation_rate
FROM
    hotel_bookings
GROUP BY guest_type;
-- repeated guests have a significantly lower rate of cancellations.


-- ADR/booking changes: repeat vs. new guests
SELECT 
    CASE
        WHEN is_repeated_guest = 1 THEN 'repeat_guests'
        ELSE 'new_guests'
    END AS guest_type,
    ROUND(IFNULL(AVG(CASE
                        WHEN is_canceled = 0 THEN adr
                    END),
                    0),
            2) AS avg_adr
FROM
    hotel_bookings
GROUP BY guest_type;
-- avg_adr fro new guests is nearly 50% above repeat_guests.

SELECT 
    CASE
        WHEN is_repeated_guest = 1 THEN 'repeat_guests'
        ELSE 'new_guests'
    END AS guest_type,
    ROUND(IFNULL(AVG(CASE
                        WHEN is_canceled = 0 THEN booking_changes
                    END),
                    0),
            2) AS avg_booking_changes
FROM
    hotel_bookings
GROUP BY guest_type;
-- Interestingly avg_booking_changes remail equal for both categories.


-- Do special requests correlate with lower cancellation (engaged guest theory)?
SELECT 
    total_of_special_requests,
    COUNT(*) AS total_bookings_received,
    COUNT(CASE
        WHEN is_canceled = 1 THEN booking_id
    END) AS cancellations,
    ROUND(100 * COUNT(CASE
                WHEN is_canceled = 1 THEN booking_id
            END) / COUNT(*),
            2) AS cancellation_rate
FROM
    hotel_bookings
GROUP BY total_of_special_requests
ORDER BY cancellation_rate;
-- As the number of special request increase, the cancellation rate decrease. 
-- Negative linear relation.

-- CORRECTED: row-level correlation (previously computed across only 6 grouped values, which inflated the coefficient to -0.97)
SELECT 
    (AVG(total_of_special_requests * is_canceled) - AVG(total_of_special_requests) * AVG(is_canceled)) / (STDDEV_POP(total_of_special_requests) * STDDEV_POP(is_canceled)) AS correlation_coefficient
FROM
    hotel_bookings;
-- Row-level correlation is -0.12 (weak-to-moderate negative), not -0.97.
-- Direction of the relationship holds, but the earlier figure was computed on only 6 aggregated data points, not the full 87,221 rows.


-- Car parking requests by hotel type and customer type.
SELECT 
    customer_type,
    ROUND(AVG(required_car_parking_spaces), 2) AS avg_parking_space_required
FROM
    hotel_bookings
GROUP BY customer_type;