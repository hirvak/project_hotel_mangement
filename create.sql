-- ============================================================
-- 1️⃣ RESET DATABASE
-- ============================================================
DROP DATABASE IF EXISTS hotel_management_;
CREATE DATABASE hotel_management_;
USE hotel_management_;

-- ============================================================
-- 2️⃣ DROP ALL EXISTING TABLES (if any)
-- ============================================================
DROP TABLE IF EXISTS Review;
DROP TABLE IF EXISTS Booking_Service;
DROP TABLE IF EXISTS Payment;
DROP TABLE IF EXISTS Bookings;
DROP TABLE IF EXISTS Services;
DROP TABLE IF EXISTS Rooms;
DROP TABLE IF EXISTS Room_Type;
DROP TABLE IF EXISTS Staff_Details;
DROP TABLE IF EXISTS Staff;
DROP TABLE IF EXISTS Guest;
DROP TABLE IF EXISTS Contact_Info;
DROP TABLE IF EXISTS Users;
DROP TABLE IF EXISTS staging_all_data;

-- ============================================================
-- 3️⃣ CREATE STAGING TABLE (Raw CSV data)
-- ============================================================
CREATE TABLE staging_all_data (
    user_id BIGINT,
    username VARCHAR(100),
    password VARCHAR(255),
    role VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20),

    staff_id BIGINT,
    staff_user_id BIGINT,
    staff_name VARCHAR(100),
    staff_role VARCHAR(50),
    salary DECIMAL(10,2),
    shift VARCHAR(50),

    guest_id BIGINT,
    guest_name VARCHAR(100),
    address VARCHAR(255),
    gender VARCHAR(10),
    id_proof VARCHAR(100),

    room_id BIGINT,
    room_no VARCHAR(10),
    room_type VARCHAR(50),
    price_per_night VARCHAR(50),
    room_status VARCHAR(50),

    booking_id BIGINT,
    check_in VARCHAR(20),
    check_out VARCHAR(20),
    no_of_guests INT,
    booking_status VARCHAR(50),

    payment_id BIGINT,
    amount DECIMAL(10,2),
    payment_date VARCHAR(25),
    payment_mode VARCHAR(50),
    payment_status VARCHAR(50),

    service_id BIGINT,
    service_name VARCHAR(100),
    service_price DECIMAL(10,2),
    quantity INT,

    review_id BIGINT,
    rating INT,
    comments TEXT,
    review_date VARCHAR(25)
);

-- ============================================================
-- 4️⃣ USERS & CONTACT INFO
-- ============================================================
CREATE TABLE Users (
    user_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin','staff','guest') NOT NULL
);

CREATE TABLE Contact_Info (
    contact_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

INSERT INTO Users (username, password, role)
SELECT username, MIN(password), MIN(role)
FROM staging_all_data
WHERE username IS NOT NULL AND role IN ('admin','staff','guest')
GROUP BY username;

INSERT INTO Contact_Info (user_id, email, phone)
SELECT u.user_id, s.email, s.phone
FROM staging_all_data s
JOIN Users u ON TRIM(s.username) = u.username
WHERE s.email IS NOT NULL OR s.phone IS NOT NULL;

-- ============================================================
-- 5️⃣ GUEST INFORMATION
-- ============================================================
CREATE TABLE Guest (
    guest_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(255),
    gender VARCHAR(10),
    id_proof VARCHAR(100),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    CONSTRAINT chk_gender CHECK (gender IN ('Male','Female','Other','Unknown'))
);

INSERT INTO Guest (user_id, name, address, gender, id_proof)
SELECT u.user_id,
       MIN(s.guest_name),
       MIN(s.address),
       CASE 
         WHEN LOWER(TRIM(MIN(s.gender))) IN ('m','male') THEN 'Male'
         WHEN LOWER(TRIM(MIN(s.gender))) IN ('f','female') THEN 'Female'
         WHEN LOWER(TRIM(MIN(s.gender))) IN ('other','o') THEN 'Other'
         ELSE 'Unknown'
       END,
       MIN(s.id_proof)
FROM staging_all_data s
JOIN Users u ON TRIM(s.username) = u.username
WHERE s.guest_name IS NOT NULL
GROUP BY u.user_id;

-- ============================================================
-- 6️⃣ STAFF INFORMATION
-- ============================================================
CREATE TABLE Staff (
    staff_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

CREATE TABLE Staff_Details (
    detail_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    staff_id BIGINT NOT NULL,
    role VARCHAR(50),
    salary DECIMAL(10,2),
    shift VARCHAR(50),
    FOREIGN KEY (staff_id) REFERENCES Staff(staff_id) ON DELETE CASCADE
);

INSERT INTO Staff (user_id, name)
SELECT u.user_id, MIN(s.staff_name)
FROM staging_all_data s
JOIN Users u ON TRIM(s.username) = u.username
WHERE s.staff_name IS NOT NULL
GROUP BY u.user_id;

INSERT INTO Staff_Details (staff_id, role, salary, shift)
SELECT st.staff_id,
       s.staff_role,
       s.salary,
       s.shift
FROM staging_all_data s
JOIN Users u ON TRIM(s.username) = u.username
JOIN Staff st ON st.user_id = u.user_id
WHERE s.staff_name IS NOT NULL;

-- ============================================================
-- 7️⃣ ROOM INFORMATION
-- ============================================================
CREATE TABLE Room_Type (
    type_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    room_type VARCHAR(50) UNIQUE NOT NULL,
    price_per_night DECIMAL(10,2) NOT NULL
);

INSERT INTO Room_Type (room_type, price_per_night)
SELECT s.room_type,
       AVG(CAST(REPLACE(REPLACE(REPLACE(s.price_per_night,'₹',''),',',''),' ','') AS DECIMAL(10,2)))
FROM staging_all_data s
WHERE s.room_type IS NOT NULL
  AND s.price_per_night REGEXP '^[0-9]+([.][0-9]+)?$'
GROUP BY s.room_type;

CREATE TABLE Rooms (
    room_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    room_no VARCHAR(10) UNIQUE NOT NULL,
    type_id BIGINT NOT NULL,
    status VARCHAR(50),
    FOREIGN KEY (type_id) REFERENCES Room_Type(type_id) ON DELETE CASCADE
);

INSERT INTO Rooms (room_no, type_id, status)
SELECT DISTINCT s.room_no,
       rt.type_id,
       s.room_status
FROM staging_all_data s
JOIN Room_Type rt ON TRIM(s.room_type) = rt.room_type
WHERE s.room_no IS NOT NULL AND s.room_type IS NOT NULL;

-- ============================================================
-- 8️⃣ BOOKINGS
-- ============================================================
CREATE TABLE Bookings (
    booking_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    guest_id BIGINT NOT NULL,
    room_id BIGINT NOT NULL,
    check_in_date DATE,
    check_out_date DATE,
    no_of_guests INT,
    booking_status VARCHAR(50),
    staff_id BIGINT,
    FOREIGN KEY (guest_id) REFERENCES Guest(guest_id),
    FOREIGN KEY (room_id) REFERENCES Rooms(room_id),
    FOREIGN KEY (staff_id) REFERENCES Staff(staff_id)
);

INSERT INTO Bookings (guest_id, room_id, check_in_date, check_out_date, no_of_guests, booking_status, staff_id)
SELECT g.guest_id,
       r.room_id,
       CASE 
         WHEN s.check_in IS NULL OR TRIM(s.check_in) = '' OR s.check_in NOT REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' 
         THEN NULL
         ELSE STR_TO_DATE(s.check_in,'%d-%m-%Y')
       END,
       CASE 
         WHEN s.check_out IS NULL OR TRIM(s.check_out) = '' OR s.check_out NOT REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
         THEN NULL
         ELSE STR_TO_DATE(s.check_out,'%d-%m-%Y')
       END,
       COALESCE(s.no_of_guests,1),
       COALESCE(s.booking_status,'Confirmed'),
       st.staff_id
FROM staging_all_data s
JOIN Guest g ON s.guest_id = g.user_id
LEFT JOIN Rooms r ON s.room_no = r.room_no
LEFT JOIN Staff st ON s.staff_user_id = st.user_id
WHERE s.booking_id IS NOT NULL
  AND s.guest_id IS NOT NULL;

-- ============================================================
-- 9️⃣ SERVICES AND BOOKING_SERVICES
-- ============================================================
CREATE TABLE Services (
    service_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    service_name VARCHAR(100),
    service_price DECIMAL(10,2)
);

INSERT INTO Services (service_name, service_price)
SELECT DISTINCT s.service_name, s.service_price
FROM staging_all_data s
WHERE s.service_name IS NOT NULL;

CREATE TABLE Booking_Service (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT NOT NULL,
    service_id BIGINT NOT NULL,
    quantity INT,
    FOREIGN KEY (booking_id) REFERENCES Bookings(booking_id),
    FOREIGN KEY (service_id) REFERENCES Services(service_id),
    CONSTRAINT unique_booking_service UNIQUE (booking_id, service_id)
);

INSERT INTO Booking_Service (booking_id, service_id, quantity)
SELECT b.booking_id,
       sv.service_id,
       COALESCE(s.quantity,1)
FROM staging_all_data s
JOIN Services sv ON s.service_name = sv.service_name
JOIN Bookings b ON s.booking_id = b.booking_id
WHERE s.service_name IS NOT NULL;

-- ============================================================
-- 🔟 PAYMENTS
-- ============================================================
CREATE TABLE Payment (
    payment_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT NOT NULL,
    amount DECIMAL(10,2),
    payment_date DATETIME,
    payment_mode VARCHAR(50),
    status VARCHAR(50),
    FOREIGN KEY (booking_id) REFERENCES Bookings(booking_id)
);

INSERT INTO Payment (booking_id, amount, payment_date, payment_mode, status)
SELECT b.booking_id,
       s.amount,
       CASE 
         WHEN s.payment_date IS NULL 
              OR TRIM(s.payment_date) = '' 
              OR s.payment_date NOT REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4} [0-9]{2}:[0-9]{2}$'
         THEN NULL
         ELSE STR_TO_DATE(s.payment_date,'%d-%m-%Y %H:%i')
       END,
       s.payment_mode,
       s.payment_status
FROM staging_all_data s
JOIN Bookings b ON s.booking_id = b.booking_id
WHERE s.payment_id IS NOT NULL;
select * from Payment;
-- ============================================================
-- 11️⃣ REVIEWS
-- ============================================================
CREATE TABLE Review (
    review_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    guest_id BIGINT,
    booking_id BIGINT,
    rating INT,
    comments TEXT,
    review_date DATETIME,
    FOREIGN KEY (guest_id) REFERENCES Guest(guest_id),
    FOREIGN KEY (booking_id) REFERENCES Bookings(booking_id)
);

INSERT INTO Review (guest_id, booking_id, rating, comments, review_date)
SELECT g.guest_id,
       b.booking_id,
       COALESCE(s.rating,5),
       COALESCE(s.comments,'No comments'),
       CASE 
         WHEN s.review_date IS NULL 
              OR TRIM(s.review_date) = '' 
              OR s.review_date NOT REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}([ ][0-9]{2}:[0-9]{2})?$'
         THEN NOW()
         ELSE STR_TO_DATE(TRIM(s.review_date),
                CASE WHEN LENGTH(TRIM(s.review_date)) = 10 THEN '%d-%m-%Y'
                     ELSE '%d-%m-%Y %H:%i'
                END)
       END
FROM staging_all_data s
JOIN Guest g ON s.guest_id = g.user_id
JOIN Bookings b ON s.booking_id = b.booking_id
WHERE s.rating IS NOT NULL OR s.comments IS NOT NULL;
select * from Review;
-- ============================================================
-- ✅ END OF SCRIPT
-- ============================================================
