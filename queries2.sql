-- ============================================================
-- Hotel Management - Comprehensive Query Library (MySQL)
-- Purpose: college presentation + practice explanations
-- File: Hotel_Management_Queries.sql
-- Schema assumed: Users, Contact_Info, Guest, Staff, Staff_Details,
-- Room_Type, Rooms, Bookings, Services, Booking_Service, Payment, Review
-- Author: ChatGPT (prepared for student showcase)
-- Note: comments explain what each query does and what kind of output to expect
-- ============================================================

/* ----------------------------------------------------------------
   SECTION A: QUICK / SIMPLE SELECTS (single-table reads)
   ---------------------------------------------------------------- */

-- 1. Show all users (basic)
SELECT * FROM Users;

-- 2. List all guests (from Guest table)
SELECT guest_id, user_id, name, gender FROM Guest ORDER BY name;

-- 3. Rooms currently marked Available
SELECT room_no, status FROM Rooms WHERE status = 'Available' ORDER BY room_no;

-- 4. All services and prices
SELECT service_id, service_name, service_price FROM Services ORDER BY service_name;

-- 5. Recent payments (latest 10)
SELECT * FROM Payment ORDER BY payment_date DESC LIMIT 10;

-- 6. Reviews with rating and short comment preview
SELECT review_id, guest_id, rating, LEFT(comments,60) AS preview, review_date FROM Review ORDER BY review_date DESC LIMIT 20;

/* ----------------------------------------------------------------
   SECTION B: FILTERS, LIKE, RANGE, NULL checks
   ---------------------------------------------------------------- */

-- 7. Guests whose name contains 'Singh' (case-insensitive)
SELECT * FROM Guest WHERE name LIKE '%Singh%';

-- 8. Rooms with status not available (negation and IN)
SELECT * FROM Rooms WHERE status NOT IN ('Available');

-- 9. Payments missing payment_date
SELECT * FROM Payment WHERE payment_date IS NULL;

-- 10. Bookings between two dates (example range)
SELECT * FROM Bookings WHERE check_in_date BETWEEN '2025-01-01' AND '2025-12-31';

-- 11. Services priced above average (uses a subquery)
SELECT * FROM Services WHERE service_price > (SELECT AVG(service_price) FROM Services);

/* ----------------------------------------------------------------
   SECTION C: JOINS (INNER / LEFT / RIGHT / CROSS) and multi-table reads
   ---------------------------------------------------------------- */

-- 12. Guest contact details (Users + Contact_Info + Guest)
SELECT U.username, C.email, C.phone, G.name, G.address
FROM Users U
JOIN Contact_Info C ON U.user_id = C.user_id
JOIN Guest G ON U.user_id = G.user_id
WHERE U.role = 'guest';

-- 13. Booking details with guest, room and room type
SELECT B.booking_id, G.name AS guest_name, R.room_no, RT.room_type, B.check_in_date, B.check_out_date, B.booking_status
FROM Bookings B
JOIN Guest G ON B.guest_id = G.guest_id
JOIN Rooms R ON B.room_id = R.room_id
JOIN Room_Type RT ON R.type_id = RT.type_id
ORDER BY B.check_in_date DESC;

-- 14. Payments with guest and room info
SELECT P.payment_id, P.amount, P.payment_date, G.name AS guest_name, R.room_no
FROM Payment P
JOIN Bookings B ON P.booking_id = B.booking_id
JOIN Guest G ON B.guest_id = G.guest_id
JOIN Rooms R ON B.room_id = R.room_id
ORDER BY P.payment_date DESC;

-- 15. Services used per booking with quantities
SELECT B.booking_id, G.name AS guest_name, SV.service_name, BS.quantity
FROM Booking_Service BS
JOIN Bookings B ON BS.booking_id = B.booking_id
JOIN Services SV ON BS.service_id = SV.service_id
JOIN Guest G ON B.guest_id = G.guest_id
ORDER BY B.booking_id;

-- 16. Staff handling bookings along with their roles
SELECT S.name AS staff_name, SD.role, COUNT(B.booking_id) AS bookings_handled
FROM Staff S
LEFT JOIN Staff_Details SD ON S.staff_id = SD.staff_id
LEFT JOIN Bookings B ON S.staff_id = B.staff_id
GROUP BY S.staff_id, S.name, SD.role
ORDER BY bookings_handled DESC;

-- 17. Guests who left reviews and their booking ids
SELECT DISTINCT G.name, R.rating, R.comments, R.booking_id
FROM Review R
JOIN Guest G ON R.guest_id = G.guest_id
ORDER BY R.review_date DESC;

/* ----------------------------------------------------------------
   SECTION D: AGGREGATES, GROUP BY, HAVING
   ---------------------------------------------------------------- */

-- 18. Count total users by role
SELECT role, COUNT(*) AS total_users FROM Users GROUP BY role;

-- 19. Total revenue (Completed payments) per month
SELECT DATE_FORMAT(payment_date,'%Y-%m') AS month, SUM(amount) AS revenue
FROM Payment
WHERE status = 'Completed' AND payment_date IS NOT NULL
GROUP BY month
ORDER BY month;

-- 20. Average price per room type (join Rooms -> Room_Type)
SELECT RT.room_type, AVG(RT.price_per_night) AS avg_price FROM Room_Type RT JOIN Rooms R ON R.type_id = RT.type_id GROUP BY RT.room_type;

-- 21. Most used service (by total quantity)
SELECT SV.service_name, SUM(BS.quantity) AS total_qty
FROM Booking_Service BS
JOIN Services SV ON BS.service_id = SV.service_id
GROUP BY SV.service_id, SV.service_name
ORDER BY total_qty DESC
LIMIT 5;

-- 22. Guests with more than 1 booking (HAVING)
SELECT G.name, COUNT(B.booking_id) AS bookings_count
FROM Guest G
JOIN Bookings B ON G.guest_id = B.guest_id
GROUP BY G.guest_id
HAVING COUNT(B.booking_id) > 1;

-- 23. Room types with occupancy percentage (booked rooms / total rooms)
SELECT RT.room_type,
       ROUND( (COUNT(B.booking_id) / NULLIF(COUNT(R.room_id),0) ) * 100,2) AS occupancy_pct
FROM Room_Type RT
JOIN Rooms R ON R.type_id = RT.type_id
LEFT JOIN Bookings B ON R.room_id = B.room_id
GROUP BY RT.room_type;

/* ----------------------------------------------------------------
   SECTION E: SUBQUERIES (scalar, correlated) and EXISTS
   ---------------------------------------------------------------- */

-- 24. Guests who have made a payment > average payment (correlated subquery)
SELECT DISTINCT G.name
FROM Guest G
JOIN Bookings B ON G.guest_id = B.guest_id
JOIN Payment P ON B.booking_id = P.booking_id
WHERE P.amount > (SELECT AVG(amount) FROM Payment WHERE status='Completed');

-- 25. Rooms never booked (NOT EXISTS)
SELECT R.room_no
FROM Rooms R
WHERE NOT EXISTS (SELECT 1 FROM Bookings B WHERE B.room_id = R.room_id);

-- 26. Latest review per guest (correlated subquery)
SELECT R1.*
FROM Review R1
WHERE R1.review_date = (
    SELECT MAX(R2.review_date) FROM Review R2 WHERE R2.guest_id = R1.guest_id
);

/* ----------------------------------------------------------------
   SECTION F: WINDOW FUNCTIONS (rank, row_number, running totals)
   MySQL 8+ required
   ---------------------------------------------------------------- */

-- 27. Top 5 guests by total spending (using window functions to rank)
SELECT guest_spend.*, RANK() OVER (ORDER BY total_spent DESC) AS rank
FROM (
    SELECT G.guest_id, G.name, COALESCE(SUM(P.amount),0) AS total_spent
    FROM Guest G
    LEFT JOIN Bookings B ON G.guest_id = B.guest_id
    LEFT JOIN Payment P ON B.booking_id = P.booking_id
    GROUP BY G.guest_id, G.name
) AS guest_spend
ORDER BY total_spent DESC
LIMIT 5;

-- 28. Running revenue over time (cumulative sum)
SELECT DATE(payment_date) AS day, SUM(amount) AS daily_revenue,
       SUM(SUM(amount)) OVER (ORDER BY DATE(payment_date)) AS cumulative_revenue
FROM Payment
WHERE status='Completed' AND payment_date IS NOT NULL
GROUP BY DATE(payment_date)
ORDER BY DATE(payment_date);

/* ----------------------------------------------------------------
   SECTION G: CTEs for readability and complex flows
   ---------------------------------------------------------------- */

-- 29. Monthly bookings + revenue using CTEs
WITH monthly_bookings AS (
    SELECT DATE_FORMAT(check_in_date,'%Y-%m') AS month, COUNT(*) AS bookings_count
    FROM Bookings
    GROUP BY month
),
monthly_revenue AS (
    SELECT DATE_FORMAT(payment_date,'%Y-%m') AS month, SUM(amount) AS revenue
    FROM Payment WHERE status='Completed'
    GROUP BY month
)
SELECT mb.month, mb.bookings_count, COALESCE(mr.revenue,0) AS revenue
FROM monthly_bookings mb
LEFT JOIN monthly_revenue mr ON mb.month = mr.month
ORDER BY mb.month;

/* ----------------------------------------------------------------
   SECTION H: MODIFICATION / DML EXAMPLES (safe examples)
   ---------------------------------------------------------------- */

-- 30. Mark a booking as Cancelled
UPDATE Bookings SET booking_status = 'Cancelled' WHERE booking_id = 123;

-- 31. Insert a new service
INSERT INTO Services (service_name, service_price) VALUES ('Laundry - Express', 299.00);

-- 32. Add a payment (example)
INSERT INTO Payment (booking_id, amount, payment_date, payment_mode, status)
VALUES (101, 4500.00, NOW(), 'Credit Card', 'Completed');

/* ----------------------------------------------------------------
   SECTION I: TRANSACTIONS and SAFETY (example)
   ---------------------------------------------------------------- */

-- 33. Transactional payment + status update (pseudocode)
START TRANSACTION;
    INSERT INTO Payment (booking_id, amount, payment_date, payment_mode, status)
    VALUES (201, 8000.00, NOW(), 'UPI', 'Completed');
    UPDATE Bookings SET booking_status = 'CheckedOut' WHERE booking_id = 201;
COMMIT;

/* ----------------------------------------------------------------
   SECTION J: ANALYTICAL QUERIES / INSIGHTS (for presentation)
   ---------------------------------------------------------------- */

-- 34. Most profitable room type (total revenue by room type)
SELECT RT.room_type, SUM(P.amount) AS revenue
FROM Payment P
JOIN Bookings B ON P.booking_id = B.booking_id
JOIN Rooms R ON B.room_id = R.room_id
JOIN Room_Type RT ON R.type_id = RT.type_id
WHERE P.status='Completed'
GROUP BY RT.room_type
ORDER BY revenue DESC
LIMIT 1;

-- 35. Peak booking month (by bookings count)
SELECT DATE_FORMAT(check_in_date,'%Y-%m') AS month, COUNT(*) AS total_bookings
FROM Bookings
GROUP BY month
ORDER BY total_bookings DESC
LIMIT 1;

-- 36. Average length of stay (in days)
SELECT AVG(DATEDIFF(check_out_date, check_in_date)) AS avg_stay_days FROM Bookings WHERE check_in_date IS NOT NULL AND check_out_date IS NOT NULL;

-- 37. Payment mode distribution (percentage)
SELECT payment_mode, COUNT(*) AS cnt, ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM Payment WHERE payment_date IS NOT NULL),2) AS pct
FROM Payment
GROUP BY payment_mode
ORDER BY cnt DESC;

/* ----------------------------------------------------------------
   SECTION K: SECURITY / VALIDATION QUERIES (data quality checks)
   ---------------------------------------------------------------- */

-- 38. Duplicate usernames (should be none if UNIQUE)
SELECT username, COUNT(*) FROM Users GROUP BY username HAVING COUNT(*) > 1;

-- 39. Bookings where check_out < check_in (data error)
SELECT * FROM Bookings WHERE check_in_date IS NOT NULL AND check_out_date IS NOT NULL AND check_out_date < check_in_date;

-- 40. Payments linked to non-existing bookings (referential integrity issues)
SELECT P.* FROM Payment P LEFT JOIN Bookings B ON P.booking_id = B.booking_id WHERE B.booking_id IS NULL;

/* ----------------------------------------------------------------
   SECTION L: ADVANCED / COMBINED USEFUL EXAMPLES
   ---------------------------------------------------------------- */

-- 41. Guests who used a particular service (e.g., 'Breakfast')
SELECT DISTINCT G.name
FROM Booking_Service BS
JOIN Services S ON BS.service_id = S.service_id
JOIN Bookings B ON BS.booking_id = B.booking_id
JOIN Guest G ON B.guest_id = G.guest_id
WHERE S.service_name = 'Gym Trainer';

-- 42. Top N rooms by revenue
SELECT R.room_no, SUM(P.amount) AS revenue
FROM Rooms R
JOIN Bookings B ON R.room_id = B.room_id
JOIN Payment P ON B.booking_id = P.booking_id
WHERE P.status = 'Completed'
GROUP BY R.room_id, R.room_no
ORDER BY revenue DESC
LIMIT 10;

-- 43. Average spend per guest (only completed payments)
SELECT G.name, COALESCE(SUM(P.amount),0) / NULLIF(COUNT(DISTINCT B.booking_id),0) AS avg_spend_per_booking
FROM Guest G
LEFT JOIN Bookings B ON G.guest_id = B.guest_id
LEFT JOIN Payment P ON B.booking_id = P.booking_id AND P.status='Completed'
GROUP BY G.guest_id, G.name
ORDER BY avg_spend_per_booking DESC;

-- 44. Identify frequent customers (top 10 by bookings)
SELECT G.name, COUNT(B.booking_id) AS bookings_count
FROM Guest G
JOIN Bookings B ON G.guest_id = B.guest_id
GROUP BY G.guest_id
ORDER BY bookings_count DESC
LIMIT 10;

-- 45. Find bookings with missing guest (data integrity)
SELECT B.* FROM Bookings B LEFT JOIN Guest G ON B.guest_id = G.guest_id WHERE G.guest_id IS NULL;

/* ----------------------------------------------------------------
   SECTION M: EXPORT / REPORT QUERIES (presentation-ready)
   ---------------------------------------------------------------- */

-- 46. Report: Monthly Summary (bookings, revenue, avg stay)
WITH monthly AS (
    SELECT DATE_FORMAT(check_in_date,'%Y-%m') AS month,
           COUNT(*) AS bookings_cnt,
           AVG(DATEDIFF(check_out_date, check_in_date)) AS avg_stay
    FROM Bookings
    GROUP BY month
),
revenues AS (
    SELECT DATE_FORMAT(payment_date,'%Y-%m') AS month, SUM(amount) AS revenue
    FROM Payment WHERE status='Completed'
    GROUP BY month
)
SELECT m.month, m.bookings_cnt, COALESCE(r.revenue,0) AS revenue, ROUND(m.avg_stay,2) AS avg_stay
FROM monthly m
LEFT JOIN revenues r ON m.month = r.month
ORDER BY m.month DESC LIMIT 24;

/* ----------------------------------------------------------------
   SECTION N: HELPFUL UTILITY QUERIES (for instructors / debugging)
   ---------------------------------------------------------------- */
-- 47. Show table row counts for quick dataset overview
SELECT 'Users' AS table_name, COUNT(*) AS cnt FROM Users
UNION ALL
SELECT 'Contact_Info', COUNT(*) FROM Contact_Info
UNION ALL
SELECT 'Guest', COUNT(*) FROM Guest
UNION ALL
SELECT 'Staff', COUNT(*) FROM Staff
UNION ALL
SELECT 'Staff_Details', COUNT(*) FROM Staff_Details
UNION ALL
SELECT 'Room_Type', COUNT(*) FROM Room_Type
UNION ALL
SELECT 'Rooms', COUNT(*) FROM Rooms
UNION ALL
SELECT 'Bookings', COUNT(*) FROM Bookings
UNION ALL
SELECT 'Payment', COUNT(*) FROM Payment
UNION ALL
SELECT 'Services', COUNT(*) FROM Services
UNION ALL
SELECT 'Booking_Service', COUNT(*) FROM Booking_Service
UNION ALL
SELECT 'Review', COUNT(*) FROM Review;

-- End of query library
-- You can copy & paste queries into your SQL client. Edit literals (dates, ids) to match your data when needed.
