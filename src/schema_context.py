# ============================================
# READ POSTGRESQL SCHEMA
# ============================================

from db import get_connection


def get_schema_context():
    """
    Read tables and columns from analytics schema.
    """

    conn = get_connection()
    cursor = conn.cursor()

    query = """
    SELECT
        table_name,
        column_name,
        data_type
    FROM information_schema.columns
    WHERE table_schema = 'analytics'
    ORDER BY table_name, ordinal_position;
    """

    cursor.execute(query)

    rows = cursor.fetchall()

    cursor.close()
    conn.close()

    schema_text = ""

    current_table = None

    for table_name, column_name, data_type in rows:

        if table_name != current_table:
            schema_text += f"\nTable: analytics.{table_name}\n"
            current_table = table_name

        schema_text += f"- {column_name} ({data_type})\n"

    return schema_text


# Test
if __name__ == "__main__":

    print("DATABASE SCHEMA")
    print("==============================")

    print(get_schema_context())