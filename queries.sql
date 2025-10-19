/*
===============================================================
          HOTEL MANAGEMENT SYSTEM - QUERY REFERENCE
          All tables: Users, Guest, Staff, Rooms, Bookings,
          Payment, Services, Booking_Service, Review
          Prepared for presentation/demo
===============================================================
*/

/* ============================================================
   1️⃣ USERS TABLE QUERIES
============================================================ */
-- Show all users
SELECT * FROM Users;

-- Show only Guests
SELECT U.username, C.email, C.phone
FROM Users U
LEFT JOIN Contact_Info C ON U.user_id = C.user_id
WHERE U.role = 'guest';

-- Show all admins
SELECT U.username, C.email, C.phone
FROM Users U
JOIN Contact_Info C ON U.user_id = C.user_id
WHERE U.role = 'admin';

-- Users with both email and phone missing
SELECT U.username
FROM Users U
LEFT JOIN Contact_Info C ON U.user_id = C.user_id
WHERE C.email IS NULL AND C.phone IS NULL;

-- Count users by role
SELECT role, COUNT(*) AS total_users
FROM Users
GROUP BY role;

-- Find roles having more than 2 users
SELECT role, COUNT(*) AS total_users
FROM Users
GROUP BY role
HAVING COUNT(*) > 2;

-- Show Guests with their Guest details
SELECT U.username, G.name, G.address
FROM Users U
INNER JOIN Guest G ON U.user_id = G.user_id;

-- Find staff with phone starting with '9876'
SELECT U.username, C.phone
FROM Users U
JOIN Contact_Info C ON U.user_id = C.user_id
WHERE U.role = 'staff' AND C.phone LIKE '987%';


/* ============================================================
   2️⃣ GUEST TABLE QUERIES
============================================================ */
-- Show all guest details
SELECT * FROM Guest;

-- Guests in Mumbai
SELECT G.name, C.phone
FROM Guest G
LEFT JOIN Contact_Info C ON G.user_id = C.user_id
WHERE G.address LIKE '%Mumbai%';

-- Count male and female guests
SELECT gender, COUNT(*) AS total
FROM Guest
GROUP BY gender;

-- Guests with Aadhar as ID proof
SELECT name, id_proof
FROM Guest
WHERE id_proof LIKE '49%';

-- Guests who have bookings more than 1
SELECT G.name, COUNT(B.booking_id) AS total_bookings
FROM Guest G
INNER JOIN Bookings B ON G.guest_id = B.guest_id
GROUP BY G.guest_id, G.name
HAVING total_bookings > 1;

-- Guests without bookings
SELECT G.name
FROM Guest G
LEFT JOIN Bookings B ON G.guest_id = B.guest_id
WHERE B.booking_id IS NULL;

-- Guests with multiple bookings
SELECT G.name, COUNT(B.booking_id) AS total_bookings
FROM Guest G
JOIN Bookings B ON G.guest_id = B.guest_id
GROUP BY G.guest_id
HAVING total_bookings > 1;

-- Guests with no reviews
SELECT G.name
FROM Guest G
LEFT JOIN Review R ON G.guest_id = R.guest_id
WHERE R.review_id IS NULL;

-- Guests who gave perfect rating (5-star)
SELECT G.name, R.comments
FROM Guest G
JOIN Review R ON G.guest_id = R.guest_id
WHERE R.rating = 5;

-- Total revenue per guest
SELECT G.name, SUM(P.amount) AS total_spent
FROM Guest G
JOIN Bookings B ON G.guest_id = B.guest_id
JOIN Payment P ON B.booking_id = P.booking_id
WHERE P.status = 'Completed'
GROUP BY G.guest_id
ORDER BY total_spent DESC;


/* ============================================================
   3️⃣ STAFF TABLE QUERIES
============================================================ */
-- Show all staff
SELECT S.*, SD.role, SD.salary, SD.shift
FROM Staff S
LEFT JOIN Staff_Details SD ON S.staff_id = SD.staff_id;

-- Join Staff with Users
SELECT U.username, SD.role, SD.salary
FROM Staff S
JOIN Staff_Details SD ON S.staff_id = SD.staff_id
JOIN Users U ON S.user_id = U.user_id;

-- Staff earning more than 30,000
SELECT S.name, SD.role, SD.salary
FROM Staff S
JOIN Staff_Details SD ON S.staff_id = SD.staff_id
WHERE SD.salary > 30000;

-- Total salary paid per role
SELECT SD.role, SUM(SD.salary) AS total_salary
FROM Staff_Details SD
GROUP BY SD.role;

-- Staff working night shift
SELECT S.name, SD.role
FROM Staff S
JOIN Staff_Details SD ON S.staff_id = SD.staff_id
WHERE SD.shift = 'Night';

-- Roles with average salary > 30000
SELECT SD.role, AVG(SD.salary) AS avg_salary
FROM Staff_Details SD
GROUP BY SD.role
HAVING AVG(SD.salary) > 30000;

-- Staff earning more than average salary
SELECT S.name, SD.salary
FROM Staff S
JOIN Staff_Details SD ON S.staff_id = SD.staff_id
WHERE SD.salary > (SELECT AVG(salary) FROM Staff_Details);

-- Count staff roles
SELECT SD.role, COUNT(*) AS total_staff
FROM Staff_Details SD
GROUP BY SD.role;

-- Staff shift distribution
SELECT SD.shift, COUNT(*) AS total_staff
FROM Staff_Details SD
GROUP BY SD.shift;

-- Staff performance: number of bookings handled
SELECT S.name, COUNT(B.booking_id) AS bookings_handled
FROM Staff S
LEFT JOIN Bookings B ON S.staff_id = B.staff_id
GROUP BY S.staff_id, S.name
ORDER BY bookings_handled DESC;

-- Staff handling bookings above average
SELECT S.name, COUNT(B.booking_id) AS bookings_handled
FROM Staff S
LEFT JOIN Bookings B ON S.staff_id = B.staff_id
GROUP BY S.staff_id, S.name
HAVING bookings_handled > (
    SELECT AVG(bookings_count)
    FROM (
        SELECT COUNT(booking_id) AS bookings_count
        FROM Bookings
        GROUP BY staff_id
    ) AS temp
);

-- Count how many Managers exist
SELECT COUNT(*) AS total_managers
FROM Staff S
JOIN Staff_Details SD ON S.staff_id = SD.staff_id
WHERE SD.role = 'manager';


/* ============================================================
   4️⃣ ROOMS TABLE QUERIES
============================================================ */
-- Show all rooms
SELECT * FROM Rooms;

-- Available rooms only
SELECT R.room_no, RT.room_type, RT.price_per_night
FROM Rooms R
JOIN Room_Type RT ON R.type_id = RT.type_id
WHERE R.status = 'Available';

-- Average price for each room type
SELECT RT.room_type, AVG(RT.price_per_night) AS avg_price
FROM Rooms R
JOIN Room_Type RT ON R.type_id = RT.type_id
GROUP BY RT.room_type;

-- Count rooms per status
SELECT status, COUNT(*) AS total
FROM Rooms
GROUP BY status;

-- Room types having more than 2 rooms
SELECT RT.room_type, COUNT(*) AS total
FROM Rooms R
JOIN Room_Type RT ON R.type_id = RT.type_id
GROUP BY RT.room_type
HAVING COUNT(*) > 2;

-- Join Rooms with Bookings
SELECT R.room_no, B.booking_id, B.booking_status
FROM Rooms R
INNER JOIN Bookings B ON R.room_id = B.room_id;

-- Rooms never booked
SELECT room_no
FROM Rooms
WHERE room_id NOT IN (SELECT room_id FROM Bookings);

-- Most booked room
SELECT R.room_no, COUNT(B.booking_id) AS total_bookings
FROM Rooms R
JOIN Bookings B ON R.room_id = B.room_id
GROUP BY R.room_id
ORDER BY total_bookings DESC
LIMIT 1;

-- Room occupancy percentage
SELECT RT.room_type,
       COUNT(B.booking_id)/COUNT(R.room_id)*100 AS occupancy_percentage
FROM Rooms R
JOIN Room_Type RT ON R.type_id = RT.type_id
LEFT JOIN Bookings B ON R.room_id = B.room_id
GROUP BY RT.room_type;

-- Rooms with highest occupancy
SELECT R.room_no, COUNT(B.booking_id) AS total_bookings
FROM Rooms R
JOIN Bookings B ON R.room_id = B.room_id
GROUP BY R.room_id
ORDER BY total_bookings DESC
LIMIT 1;


/* ============================================================
   5️⃣ BOOKINGS TABLE QUERIES
============================================================ */
-- Show all bookings
SELECT * FROM Bookings;

-- Confirmed bookings only
SELECT G.name AS GuestName, R.room_no, B.booking_id
FROM Bookings B
JOIN Guest G ON B.guest_id = G.guest_id
JOIN Rooms R ON B.room_id = R.room_id
WHERE B.booking_status = 'Confirmed';

-- Number of guests booked per booking
SELECT booking_id, no_of_guests
FROM Bookings;

-- Count bookings per guest
SELECT G.name, COUNT(B.booking_id) AS total_bookings
FROM Bookings B
JOIN Guest G ON B.guest_id = G.guest_id
GROUP BY G.name
ORDER BY total_bookings DESC;

-- Guests having >1 confirmed booking
SELECT guest_id, COUNT(*) AS confirmed_bookings
FROM Bookings
WHERE booking_status = 'Confirmed'
GROUP BY guest_id
HAVING COUNT(*) > 1;

-- Join Bookings with Payments
SELECT B.booking_id, B.booking_status, P.status
FROM Bookings B
INNER JOIN Payment P ON B.booking_id = P.booking_id;

-- Left join Bookings with Reviews
SELECT B.booking_id, R.rating
FROM Bookings B
LEFT JOIN Review R ON B.booking_id = R.booking_id;

-- Bookings with revenue above average
SELECT B.booking_id, P.amount
FROM Bookings B
JOIN Payment P ON B.booking_id = P.booking_id
WHERE P.amount > (SELECT AVG(amount) FROM Payment);

-- Bookings handled per staff
SELECT S.name, COUNT(B.booking_id) AS bookings_handled
FROM Staff S
LEFT JOIN Bookings B ON S.staff_id = B.staff_id
GROUP BY S.staff_id, S.name;

-- Popular room type per month
SELECT DATE_FORMAT(B.check_in_date,'%Y-%m') AS month, RT.room_type, COUNT(B.booking_id) AS total_booked
FROM Bookings B
JOIN Rooms R ON B.room_id = R.room_id
JOIN Room_Type RT ON R.type_id = RT.type_id
GROUP BY month, RT.room_type
ORDER BY month, total_booked DESC;

-- Most expensive booking
SELECT B.booking_id, G.name AS guest, R.room_no, P.amount
FROM Bookings B
JOIN Guest G ON B.guest_id = G.guest_id
JOIN Rooms R ON B.room_id = R.room_id
JOIN Payment P ON B.booking_id = P.booking_id
ORDER BY P.amount DESC
LIMIT 1;


/* ============================================================
   6️⃣ PAYMENT TABLE QUERIES
============================================================ */
-- Show all payments
SELECT * FROM Payment;

-- Show failed payments
SELECT booking_id, amount, payment_mode
FROM Payment
WHERE status = 'Failed';

-- Total paid amount
SELECT SUM(amount) AS total_paid
FROM Payment
WHERE status = 'Completed';

-- Payments done via Card
SELECT payment_id, booking_id, amount
FROM Payment
WHERE payment_mode = 'Credit Card';

-- Total payment by mode
SELECT payment_mode, SUM(amount) AS total_amount
FROM Payment
GROUP BY payment_mode;

-- Payment modes with >2 successful transactions
SELECT payment_mode, COUNT(*) AS total_success
FROM Payment
WHERE status = 'Completed'
GROUP BY payment_mode
HAVING COUNT(*) > 2;

-- Payments higher than average
SELECT payment_id, amount
FROM Payment
WHERE amount > (SELECT AVG(amount) FROM Payment);

-- Revenue collected per payment mode
SELECT payment_mode, SUM(amount) AS total_revenue
FROM Payment
GROUP BY payment_mode
HAVING SUM(amount) > 1000;

-- Monthly revenue trend
SELECT DATE_FORMAT(payment_date,'%Y-%m') AS month, SUM(amount) AS revenue
FROM Payment
WHERE status='Completed'
GROUP BY month
ORDER BY month ASC;

-- Average revenue per booking
SELECT AVG(amount) AS avg_revenue
FROM Payment
WHERE status = 'Completed';

-- Total revenue collected
SELECT SUM(amount) AS total_revenue
FROM Payment
WHERE status = 'Completed';
