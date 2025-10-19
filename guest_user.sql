-- ==========================================================
-- GUEST USER ACCESS (Limited Privileges)
-- ==========================================================
-- This section defines what a guest-level user can and cannot do.
-- Guests have very limited access for security and privacy reasons.
-- They can:
--   View only their own booking and payment details (via the Guest_Bookings view)
--   Insert reviews for their own completed bookings
-- They cannot:
--   View or edit other guests’ bookings
--   Modify rooms, bookings, payments, or guest records
-- ==========================================================

USE hotel_management_;

-- (Optional) Clean up any test bookings if needed
DELETE FROM Bookings WHERE booking_id = 1;

--  Guests can view their booking details using the Guest_Bookings view
-- This view combines data from Bookings, Rooms, Payments, and Reviews for convenience
SELECT * FROM Guest_Bookings;

--  A guest can only see their own bookings (e.g., guest with user_id = 11)
SELECT * FROM Guest_Bookings WHERE user_id = 11;

--  A guest can add a review for their own completed booking
-- (Assuming booking_id = 5 belongs to guest_id = 1)
INSERT INTO Review (guest_id, booking_id, rating, comments, review_date)
VALUES (1, 5, 5, 'Excellent stay, loved the service!', NOW());

--  View privileges assigned to the guest user
-- This shows what permissions have been granted to 'guest_user'
SHOW GRANTS FOR 'guest_user'@'localhost';

--  Guests should not be able to access or modify sensitive tables directly
-- The following commands should fail for a true guest account
SELECT * FROM Bookings;  -- Not allowed
UPDATE Rooms SET status = 'Available' WHERE room_no = 101;  -- Not allowed
DELETE FROM Guest WHERE guest_id = 1;  -- Not allowed


