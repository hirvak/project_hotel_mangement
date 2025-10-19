-- ==========================================================
-- ADMIN ACCESS SCRIPT
-- Database: hotel_management
-- Description:
--   Admin has full control over the database.
--   Can create and manage views, triggers, and procedures.
--   Handles all CRUD operations, reporting, and automation.
-- ==========================================================

USE hotel_management_;

-- Clean existing sample data (optional for testing)
DELETE FROM Payment WHERE payment_id = 1;
SELECT * FROM Payment;


-- ==========================================================
-- VIEW: Guest_Bookings
-- Purpose:
--   Displays combined booking, payment, and review information 
--   for each guest in a single summarized view.
-- ==========================================================

CREATE OR REPLACE VIEW Guest_Bookings AS
SELECT 
    B.booking_id,
    R.room_no,
    R.room_type,
    B.check_in_date,
    B.check_out_date,
    B.no_of_guests,
    B.booking_status,
    G.user_id,
    COALESCE(P.amount, 0) AS payment_amount,  -- Handles nulls (no payment yet)
    COALESCE(P.status, 'Not Paid') AS payment_status,
    Rev.comments AS review_comments,
    Rev.rating AS review_rating
FROM Bookings B
JOIN Guest G ON B.guest_id = G.guest_id
JOIN Rooms R ON B.room_id = R.room_id
LEFT JOIN Payment P ON B.booking_id = P.booking_id
LEFT JOIN Review Rev ON B.booking_id = Rev.booking_id;











