-- =========================================================
-- INDEX CREATION SCRIPT
-- Database: hotel_management
-- Purpose: Improve query performance for common operations
-- =========================================================

USE hotel_management_;

-- 1. User Login Optimization
CREATE INDEX idx_username ON Users(username);

-- 2. Guest and Staff Foreign Keys
CREATE INDEX idx_guest_user_id ON Guest(user_id);
CREATE INDEX idx_staff_user_id ON Staff(user_id);

-- 3. Booking Foreign Keys
CREATE INDEX idx_booking_guest_id ON Bookings(guest_id);
CREATE INDEX idx_booking_room_id ON Bookings(room_id);
CREATE INDEX idx_booking_staff_id ON Bookings(staff_id);

-- 4. Room Lookup Optimization
CREATE INDEX idx_room_no ON Rooms(room_no);
CREATE INDEX idx_room_status ON Rooms(status);

-- 5. Payment Search Optimization
CREATE INDEX idx_payment_date ON Payment(payment_date);
CREATE INDEX idx_payment_status ON Payment(status);

-- 6. Booking Date Optimization
CREATE INDEX idx_booking_dates ON Bookings(check_in_date, check_out_date);

-- View Indexes
-- 0 → unique index (like PRIMARY KEY)
-- 1 → non-unique (normal index)
SHOW INDEX FROM Bookings;
SHOW INDEX FROM Rooms;
SHOW INDEX FROM Payment;
SHOW INDEXES FROM Guest;
SHOW INDEXES FROM Staff;
