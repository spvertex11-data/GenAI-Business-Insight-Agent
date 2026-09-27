# ============================================
# GENAI BUSINESS INSIGHT AGENT
# ============================================

from gemini import ask_gemini
from schema_context import get_schema_context
from sql_validator import validate_sql
from db import execute_query


def generate_sql(question):
    """
    Convert a natural-language business question
    into PostgreSQL SQL using Gemini.
    """

    schema = get_schema_context()

    prompt = f"""
You are an expert PostgreSQL data analyst.

Use ONLY this database schema:

{schema}

BUSINESS QUESTION:
{question}

RULES:
1. Generate PostgreSQL SQL only.
2. Use only SELECT or WITH queries.
3. Never use INSERT, UPDATE, DELETE, DROP, ALTER,
   CREATE or TRUNCATE.
4. Do not invent tables or columns.
5. Always use analytics schema before table names.
6. Revenue = qty * price from analytics.order_items.
7. Return SQL only.
8. Do not add explanations or markdown.
"""

    return ask_gemini(prompt)


def repair_sql(question, failed_sql, error_message):
    """
    Give Gemini one chance to repair failed SQL.
    """

    schema = get_schema_context()

    prompt = f"""
You are an expert PostgreSQL data analyst.

DATABASE SCHEMA:
{schema}

BUSINESS QUESTION:
{question}

FAILED SQL:
{failed_sql}

POSTGRESQL ERROR:
{error_message}

Fix the SQL.

RULES:
1. Use only SELECT or WITH.
2. Use only existing tables and columns.
3. Always use analytics schema.
4. Never use destructive SQL.
5. Return corrected SQL only.
6. Do not add explanations or markdown.
"""

    return ask_gemini(prompt)


def generate_business_insight(question, sql, columns, rows):
    """
    Generate a business explanation using actual SQL results.
    """

    # Send only first 20 rows to Gemini
    sample_rows = rows[:20]

    prompt = f"""
You are a business data analyst.

Answer the question using ONLY the SQL result below.

BUSINESS QUESTION:
{question}

SQL USED:
{sql}

RESULT COLUMNS:
{columns}

ACTUAL SQL RESULT:
{sample_rows}

RULES:
1. Do not invent numbers.
2. Use only the supplied SQL result.
3. If data is insufficient, clearly say so.
4. Keep the answer concise.
5. Give one practical recommendation.

Return exactly:

Business Insight:
Business Recommendation:
"""

    return ask_gemini(prompt)


def run_agent(question):
    """
    Complete workflow:
    Question
    -> Gemini SQL
    -> SQL validation
    -> PostgreSQL execution
    -> optional SQL repair
    -> business insight
    """

    print("\n" + "=" * 60)
    print("GENAI BUSINESS INSIGHT AGENT")
    print("=" * 60)

    print("\nBUSINESS QUESTION")
    print(question)

    # ========================================
    # STEP 1: GENERATE SQL
    # ========================================

    generated_sql = generate_sql(question)

    # Gemini may return None if quota/server fails
    if not generated_sql:
        print("\nSQL generation unavailable.")
        print("Gemini did not return a query.")
        return

    print("\nGENERATED SQL")
    print(generated_sql)

    # ========================================
    # STEP 2: VALIDATE SQL
    # ========================================

    is_safe, message, clean_sql = validate_sql(generated_sql)

    print("\nSQL VALIDATION")
    print(message)

    if not is_safe:
        print("\nQuery blocked for safety.")
        return

    # ========================================
    # STEP 3: EXECUTE SQL
    # ========================================

    try:
        columns, rows = execute_query(clean_sql)

    except Exception as error:

        print("\nFirst SQL execution failed.")
        print("Error:", error)

        print("\nAttempting one automatic repair...")

        repaired_sql = repair_sql(
            question,
            clean_sql,
            str(error)
        )

        # Gemini may fail because of quota/server issue
        if not repaired_sql:
            print("\nSQL repair unavailable.")
            print(
                "Gemini quota may be exhausted "
                "or the service may be unavailable."
            )
            return

        print("\nREPAIRED SQL")
        print(repaired_sql)

        # Validate repaired SQL
        is_safe, message, repaired_sql = validate_sql(repaired_sql)

        print("\nREPAIRED SQL VALIDATION")
        print(message)

        if not is_safe:
            print("\nRepaired query blocked for safety.")
            return

        try:
            columns, rows = execute_query(repaired_sql)
            clean_sql = repaired_sql

        except Exception as second_error:
            print("\nSQL repair failed.")
            print("Error:", second_error)
            return

    # ========================================
    # STEP 4: SHOW DATABASE RESULT
    # ========================================

    print("\nQUERY RESULT")

    print(columns)

    # Show maximum first 10 rows in terminal
    for row in rows[:10]:
        print(row)

    if len(rows) > 10:
        print(f"... and {len(rows) - 10} more rows")

    # ========================================
    # STEP 5: GENERATE BUSINESS INSIGHT
    # ========================================

    insight = generate_business_insight(
        question,
        clean_sql,
        columns,
        rows
    )

    # Gemini may fail because of quota/server issue
    if not insight:
        print("\nBusiness insight generation unavailable.")
        print("The SQL result was retrieved successfully.")
        return

    print("\nFINAL BUSINESS ANSWER")
    print(insight)


# ============================================
# INTERACTIVE CLI
# ============================================

if __name__ == "__main__":

    print("\n" + "=" * 60)
    print("GENAI BUSINESS INSIGHT AGENT")
    print("=" * 60)

    print("\nAsk a business question.")
    print("Type 'exit' to close the agent.")

    while True:

        question = input("\nBusiness Question: ").strip()

        # Exit program
        if question.lower() == "exit":
            print("\nAgent closed.")
            break

        # Prevent empty input
        if not question:
            print("Please enter a business question.")
            continue

        # Run agent
        run_agent(question)