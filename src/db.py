# ============================================
# DATABASE CONNECTION + QUERY EXECUTION
# ============================================

import os
import psycopg2
from dotenv import load_dotenv

# Load .env values
load_dotenv()

DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")


def get_connection():
    """
    Create PostgreSQL connection.
    """

    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )


def execute_query(sql):
    """
    Execute a read-only SQL query.
    Returns column names and result rows.
    """

    conn = get_connection()
    cursor = conn.cursor()

    try:
        cursor.execute(sql)

        # Get column names
        columns = [desc[0] for desc in cursor.description]

        # Get result rows
        rows = cursor.fetchall()

        return columns, rows

    finally:
        cursor.close()
        conn.close()


# Test database connection
if __name__ == "__main__":

    try:
        conn = get_connection()
        print("PostgreSQL connection successful.")
        conn.close()

    except Exception as error:
        print("PostgreSQL connection failed.")
        print("Error:", error)