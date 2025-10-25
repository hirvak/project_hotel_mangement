# db_config.py
# Database connection pool for hotel_management_ DB
# Replace placeholders with your credentials

from mysql.connector import pooling

DB_CONFIG = {
    'host': 'localhost',
    'user': 'your_username',        # <- placeholder
    'password': 'your_password',    # <- placeholder
    'database': 'hotel_management_'
}

# Connection pool (change pool_size if needed)
connection_pool = pooling.MySQLConnectionPool(
    pool_name='hotel_pool',
    pool_size=5,
    **DB_CONFIG
)

def get_db_connection():
    """
    Returns a pooled MySQL connection.
    Remember to close the connection (conn.close()) after use.
    """
    return connection_pool.get_connection()
