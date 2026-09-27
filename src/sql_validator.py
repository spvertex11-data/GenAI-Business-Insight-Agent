# ============================================
# SQL SAFETY VALIDATOR
# ============================================

import re


def clean_sql(sql):
    """
    Remove markdown code fences returned by Gemini.
    """

    sql = sql.strip()

    # Remove ```sql and ```
    sql = re.sub(r"^```sql\s*", "", sql, flags=re.IGNORECASE)
    sql = re.sub(r"^```\s*", "", sql)
    sql = re.sub(r"\s*```$", "", sql)

    return sql.strip()


def validate_sql(sql):
    """
    Allow only safe read-only SQL.
    """

    sql = clean_sql(sql)

    sql_upper = sql.upper()

    # Query must start with SELECT or WITH
    if not (
        sql_upper.startswith("SELECT")
        or sql_upper.startswith("WITH")
    ):
        return False, "Only SELECT or WITH queries are allowed.", sql

    blocked_words = [
        "INSERT",
        "UPDATE",
        "DELETE",
        "DROP",
        "ALTER",
        "TRUNCATE",
        "CREATE",
        "GRANT",
        "REVOKE"
    ]

    for word in blocked_words:

        # Search whole SQL keywords only
        pattern = rf"\b{word}\b"

        if re.search(pattern, sql_upper):
            return False, f"Blocked SQL keyword detected: {word}", sql

    return True, "SQL is safe.", sql


# Test
if __name__ == "__main__":

    test_sql = "SELECT * FROM analytics.customers;"

    is_safe, message, cleaned_sql = validate_sql(test_sql)

    print(message)
    print(cleaned_sql)