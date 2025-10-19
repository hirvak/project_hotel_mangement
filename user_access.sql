-- Admin user: full access
CREATE USER 'admin_user'@'localhost' IDENTIFIED BY 'Admin@123';
GRANT ALL PRIVILEGES ON hotel_management_.* TO 'admin_user'@'localhost';

GRANT ALL PRIVILEGES ON hotel_management.* TO 'admin_user'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;

-- Staff user: read and update only
CREATE USER 'staff_user'@'localhost' IDENTIFIED BY 'Staff@123';
GRANT SELECT, UPDATE ON hotel_management_.Rooms TO 'staff_user'@'localhost';
GRANT SELECT, UPDATE ON hotel_management_.Bookings TO 'staff_user'@'localhost';
GRANT SELECT ON hotel_management_.Guest TO 'staff_user'@'localhost';
GRANT INSERT ON hotel_management_.Payment TO 'staff_user'@'localhost'; -- staff also record payments when guests check in or out.


SHOW PROCEDURE STATUS WHERE Db = 'hotel_management_';
GRANT INSERT ON hotel_management_.Staff_Activity_Log TO 'staff_user'@'localhost';

-- Guest user: only read access to own info
CREATE USER 'guest_user'@'localhost' IDENTIFIED BY 'Guest@123';
GRANT SELECT ON hotel_management_.Guest_Bookings TO 'guest_user'@'localhost';
GRANT INSERT ON hotel_management_.Review TO 'guest_user'@'localhost';
FLUSH PRIVILEGES;

-- Check privileges for a user
SHOW GRANTS FOR 'staff_user'@'localhost';
SHOW GRANTS FOR 'guest_user'@'localhost';

SELECT User, Host FROM mysql.user;
SET GLOBAL log_bin_trust_function_creators = 1;