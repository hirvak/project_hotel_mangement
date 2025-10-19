-- ==========================================================
-- STAFF USER ACCESS (Operational Privileges)
-- ==========================================================
-- This section defines what a staff-level user can and cannot do.
-- Staff members handle operational tasks such as managing rooms,
-- updating booking statuses, and recording payments.
--
-- They can:
--   - View and update Rooms and Bookings
--   - View Guest information (for operational reference)
--   - Record new Payments for guests
-- They cannot:
--   - Delete core data (Bookings, Guests, Rooms)
--   - Alter database structure (DROP, ALTER)
-- ==========================================================



USE hotel_management_;

-- Check tables staff_user can read
SELECT * FROM Rooms;
SELECT * FROM Bookings;

-- Try to insert payment
INSERT INTO Payment (booking_id, amount, payment_date, payment_mode, status)
VALUES (1, 500.00, NOW(), 'Cash', 'Completed');

-- Try to update room status
UPDATE Rooms SET status='Occupied' WHERE room_id=1;

UPDATE Rooms SET status = 'Occupied' WHERE room_id = 1;
INSERT INTO Payment (booking_id, amount, payment_date, payment_mode, status)
VALUES (1, 500, NOW(), 'Cash', 'Completed');
