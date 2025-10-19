-- ==========================================================
-- DATABASE: hotel_management
-- PURPOSE: Manage hotel bookings, payments, rooms, services
-- Includes: Triggers and Stored Procedures
-- ==========================================================

USE hotel_management_;

-- ==========================================================
-- 1️⃣ TRIGGER 1: Update Room Status After Booking Insert
--    Automatically marks a room as 'Occupied' when a new booking is created
-- ==========================================================
DROP TRIGGER IF EXISTS after_booking_insert;

DELIMITER $$
CREATE TRIGGER after_booking_insert
AFTER INSERT ON Bookings
FOR EACH ROW
BEGIN
    -- Update the room status to 'Occupied' after booking is inserted
    UPDATE Rooms
    SET status = 'Occupied'
    WHERE room_id = NEW.room_id;
END$$
DELIMITER ;

-- Test Trigger 1
SELECT room_id, room_no, status FROM Rooms WHERE room_id = 3;  -- Before inserting booking

INSERT INTO Bookings (guest_id, room_id, check_in_date, check_out_date, no_of_guests, booking_status, staff_id)
VALUES (1, 1, '2025-10-10', '2025-10-12', 2, 'Confirmed', 1);

SELECT room_id, room_no, status FROM Rooms WHERE room_id = 1;  -- After trigger

-- ==========================================================
-- 2️⃣ TRIGGER 2: Refund Payment After Booking Cancel
--    Automatically refunds payment and marks room 'Available' when booking is cancelled
-- ==========================================================
DROP TRIGGER IF EXISTS after_booking_cancel;

DELIMITER $$
CREATE TRIGGER after_booking_cancel
AFTER UPDATE ON Bookings
FOR EACH ROW
BEGIN
    IF NEW.booking_status = 'Cancelled' THEN
        -- Refund the payment
        UPDATE Payment
        SET status = 'Refunded'
        WHERE booking_id = NEW.booking_id;

        -- Set room status back to 'Available'
        UPDATE Rooms
        SET status = 'Available'
        WHERE room_id = NEW.room_id;
    END IF;
END$$
DELIMITER ;

-- 1️⃣ Temporarily allow zero dates
SET sql_mode = '';

-- 2️⃣ Replace invalid dates with current timestamp
UPDATE Payment
SET payment_date = NOW()
WHERE payment_date = '0000-00-00 00:00:00' OR payment_date IS NULL;

-- 3️⃣ Now modify the enum column safely
ALTER TABLE Payment  
MODIFY COLUMN status ENUM('Pending','Completed','Failed','Refunded') DEFAULT 'Pending';

-- 4️⃣ Restore strict mode (optional, recommended)
SET sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';

-- Ensure Payment status column includes 'Refunded'
ALTER TABLE Payment 
MODIFY COLUMN status ENUM('Pending','Completed','Failed','Refunded') DEFAULT 'Pending';

-- Test Trigger 2
SELECT booking_id, booking_status FROM Bookings WHERE booking_id = 1;
SELECT room_id, status FROM Rooms WHERE room_id = 1;
SELECT payment_id, status FROM Payment WHERE booking_id = 1;

UPDATE Bookings
SET booking_status = 'Cancelled'
WHERE booking_id = 1;

SELECT booking_id, booking_status FROM Bookings WHERE booking_id = 1;
SELECT room_id, status FROM Rooms WHERE room_id = 1;
SELECT payment_id, status FROM Payment WHERE booking_id = 1;

-- ==========================================================
-- 3️⃣ TRIGGER 3: Insert Default Service Charge
--    Automatically adds a pending payment whenever a new service is booked
-- ==========================================================
DROP TRIGGER IF EXISTS after_service_insert;

DELIMITER $$
CREATE TRIGGER after_service_insert
AFTER INSERT ON Booking_Service
FOR EACH ROW
BEGIN
    INSERT INTO Payment (booking_id, amount, payment_date, payment_mode, status)
    VALUES (NEW.booking_id, 50.00 * NEW.quantity, NOW(), 'Cash', 'Pending');
END$$
DELIMITER ;

-- Test Trigger 3
INSERT INTO Booking_Service (booking_id, service_id, quantity)
VALUES (2, 1, 2);

SELECT * FROM Payment
WHERE booking_id = 2
ORDER BY payment_id DESC
LIMIT 5;

-- ==========================================================
-- 4️⃣ Drop Existing Procedures (if any)
-- ==========================================================
DROP PROCEDURE IF EXISTS make_booking;
DROP PROCEDURE IF EXISTS cancel_booking;
DROP PROCEDURE IF EXISTS check_in;
DROP PROCEDURE IF EXISTS check_out;
DROP PROCEDURE IF EXISTS add_service;
DROP PROCEDURE IF EXISTS MakePayment;
DROP PROCEDURE IF EXISTS GetGuestBookings;

-- ==========================================================
-- 5️⃣ PROCEDURE 1: make_booking
--    Creates a booking, generates a payment, and updates room status
-- ==========================================================
DELIMITER $$
CREATE PROCEDURE make_booking(
    IN p_guest_id BIGINT,
    IN p_room_id BIGINT,
    IN p_check_in DATE,
    IN p_check_out DATE,
    IN p_no_of_guests INT,
    IN p_amount DECIMAL(10,2),
    IN p_payment_mode VARCHAR(50)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT '❌ Transaction Rolled Back' AS message;
    END;

    START TRANSACTION;

    -- Insert booking
    INSERT INTO Bookings (guest_id, room_id, check_in_date, check_out_date, no_of_guests, booking_status)
    VALUES (p_guest_id, p_room_id, p_check_in, p_check_out, p_no_of_guests, 'Confirmed');

    -- Insert payment
    INSERT INTO Payment (booking_id, amount, payment_date, payment_mode, status)
    VALUES (LAST_INSERT_ID(), p_amount, NOW(), p_payment_mode, 'Completed');

    -- Update room status
    UPDATE Rooms
    SET status = 'Occupied'
    WHERE room_id = p_room_id;

    COMMIT;
    SELECT '✅ Booking Successful' AS message;
END$$
DELIMITER ;

-- Test Procedure 1
CALL make_booking(1, 1, '2025-10-10', '2025-10-12', 2, 3000.00, 'Credit Card');

SELECT * FROM Bookings ORDER BY booking_id DESC LIMIT 1;
SELECT * FROM Payment ORDER BY payment_id DESC LIMIT 1;
SELECT room_id, status FROM Rooms WHERE room_id = 1;

-- ==========================================================
-- 6️⃣ PROCEDURE 2: cancel_booking
--    Cancels booking, refunds payment, marks room available
-- ==========================================================
DELIMITER $$
CREATE PROCEDURE cancel_booking(IN p_booking_id BIGINT)
BEGIN
    DECLARE v_room_id BIGINT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT '❌ Cancellation Failed. Rolled Back' AS message;
    END;

    START TRANSACTION;

    SELECT room_id INTO v_room_id FROM Bookings WHERE booking_id = p_booking_id;

    UPDATE Bookings SET booking_status = 'Cancelled' WHERE booking_id = p_booking_id;
    UPDATE Payment SET status = 'Refunded' WHERE booking_id = p_booking_id;
    UPDATE Rooms SET status = 'Available' WHERE room_id = v_room_id;

    COMMIT;
    SELECT '✅ Booking Cancelled and Payment Refunded' AS message;
END$$
DELIMITER ;

-- Test Procedure 2
CALL cancel_booking(1);
SELECT * FROM Bookings WHERE booking_id = 1;
SELECT * FROM Payment WHERE booking_id = 1;
SELECT room_id, status FROM Rooms WHERE room_id = (SELECT room_id FROM Bookings WHERE booking_id = 1);

-- ==========================================================
-- 7️⃣ PROCEDURE 3: check_in
-- ==========================================================
DELIMITER $$
CREATE PROCEDURE check_in(IN p_booking_id BIGINT)
BEGIN
    UPDATE Bookings
    SET booking_status = 'Checked-In'
    WHERE booking_id = p_booking_id;

    SELECT '✅ Guest Checked-In Successfully' AS message;
END$$
DELIMITER ;

CALL check_in(2);
SELECT booking_id, booking_status FROM Bookings WHERE booking_id = 2;

-- ==========================================================
-- 8️⃣ PROCEDURE 4: check_out
-- ==========================================================
DELIMITER $$
CREATE PROCEDURE check_out(IN p_booking_id BIGINT)
BEGIN
    DECLARE v_room_id BIGINT;

    SELECT room_id INTO v_room_id FROM Bookings WHERE booking_id = p_booking_id;

    UPDATE Bookings
    SET booking_status = 'Checked-Out'
    WHERE booking_id = p_booking_id;

    UPDATE Rooms
    SET status = 'Available'
    WHERE room_id = v_room_id;

    SELECT '✅ Guest Checked-Out and Room Marked Available' AS message;
END$$
DELIMITER ;

CALL check_out(2);
SELECT booking_id, booking_status FROM Bookings WHERE booking_id = 2;
SELECT room_id, status FROM Rooms WHERE room_id = (SELECT room_id FROM Bookings WHERE booking_id = 2);

-- ==========================================================
-- 9️⃣ PROCEDURE 5: add_service
-- ==========================================================
DELIMITER $$
CREATE PROCEDURE add_service(
    IN p_booking_id BIGINT,
    IN p_service_id BIGINT,
    IN p_quantity INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT '❌ Error Adding Service. Rolled Back' AS message;
    END;

    START TRANSACTION;

    INSERT INTO Booking_Service (booking_id, service_id, quantity)
    VALUES (p_booking_id, p_service_id, p_quantity);

    INSERT INTO Payment (booking_id, amount, payment_date, payment_mode, status)
    VALUES (p_booking_id, 50.00 * p_quantity, NOW(), 'Cash', 'Pending');

    COMMIT;
    SELECT '✅ Service Added and Payment Recorded' AS message;
END$$
DELIMITER ;

CALL add_service(3, 1, 2);
SELECT * FROM Booking_Service WHERE booking_id = 3;
SELECT * FROM Payment WHERE booking_id = 3 ORDER BY payment_id DESC LIMIT 1;

-- ==========================================================
-- 🔟 PROCEDURE 6: MakePayment
-- ==========================================================
DELIMITER $$
CREATE PROCEDURE MakePayment (
    IN p_booking_id BIGINT,
    IN p_amount DECIMAL(10,2),
    IN p_mode VARCHAR(50)
)
BEGIN
    INSERT INTO Payment (booking_id, amount, payment_date, payment_mode, status)
    VALUES (p_booking_id, p_amount, NOW(), p_mode, 'Completed');

    UPDATE Bookings
    SET booking_status = 'Paid'
    WHERE booking_id = p_booking_id
      AND booking_status <> 'Cancelled';
END$$
DELIMITER ;

CALL MakePayment(3, 450.00, 'Cash');
SELECT * FROM Payment WHERE booking_id = 3 ORDER BY payment_id DESC LIMIT 1;
SELECT booking_id, booking_status FROM Bookings WHERE booking_id = 3;

-- ==========================================================
-- 1️⃣1️⃣ PROCEDURE 7: GetGuestBookings
-- ==========================================================
DELIMITER $$
CREATE PROCEDURE GetGuestBookings (
    IN p_guest_id BIGINT
)
BEGIN
    SELECT 
        B.booking_id,
        R.room_no,
        B.check_in_date,
        B.check_out_date,
        B.booking_status,
        COALESCE(P.amount, 0) AS payment_amount,
        COALESCE(P.status, 'Not Paid') AS payment_status
    FROM Bookings B
    JOIN Rooms R ON B.room_id = R.room_id
    LEFT JOIN Payment P ON B.booking_id = P.booking_id
    WHERE B.guest_id = p_guest_id;
END$$
DELIMITER ;

CALL GetGuestBookings(1);

-- ==========================================================
-- VERIFICATION: Show all triggers and procedures
-- ==========================================================
SHOW TRIGGERS FROM hotel_management_;
SHOW PROCEDURE STATUS WHERE Db = 'hotel_management_';
