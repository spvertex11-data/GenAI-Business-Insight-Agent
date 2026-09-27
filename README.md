# GenAI Business Insight Agent

## Project Overview

The GenAI Business Insight Agent is a medium-sized analytics project built using Python, PostgreSQL, SQL, Pandas, and the Gemini API.

The goal of the project is to allow a business user to ask questions in plain English and receive data-backed answers without manually writing SQL.

The system reads the PostgreSQL schema, asks Gemini to generate read-only SQL, validates the SQL for safety, executes it against the database, and then generates a concise business insight using the actual query result.

---

## Business Problem

Business users often depend on analysts for ad-hoc questions such as:

- What is the total revenue?
- Which customers generate the highest revenue?
- Which categories are performing best?
- Which products have the most returns?
- Which month had the biggest revenue decline?
- Which cities generate the highest revenue?
- What is the total refund amount?

The project helps automate these questions while keeping SQL execution safe and result-grounded.

---

## Dataset

The project uses a relational retail dataset with hundreds of thousands of records.

Main tables used:

- customers
- orders
- order_items
- products
- categories
- payments
- returns

---

## Tech Stack

- Python
- Pandas
- PostgreSQL
- SQL
- Gemini API
- psycopg2
- python-dotenv

---

## Project Architecture

Business Question  
→ Gemini understands the question  
→ PostgreSQL schema context is provided  
→ Gemini generates SQL  
→ Python validates SQL  
→ PostgreSQL executes the approved query  
→ Actual query result is returned  
→ Gemini generates business insight  
→ Final recommendation is shown to the user

---

## Key Features

- Natural language to SQL
- Dynamic PostgreSQL schema reading
- Read-only SQL validation
- PostgreSQL query execution
- Automatic SQL repair attempt
- Gemini-based business insight generation
- Result-grounded responses
- Python/Pandas business analysis
- Error handling for Gemini quota and server issues

---

## SQL Safety

The project allows only read-only queries.

Allowed:

- SELECT
- WITH

Blocked:

- INSERT
- UPDATE
- DELETE
- DROP
- ALTER
- TRUNCATE
- CREATE
- GRANT
- REVOKE

This prevents the AI from modifying database data.

---

## Python Analysis

Python and Pandas are used for:

- Monthly revenue analysis
- Month-over-month revenue change
- Revenue decline detection
- Category revenue contribution
- Return and refund analysis

---

## Example Business Questions

1. What is the total revenue?
2. Which 5 customers generated the highest revenue?
3. Which categories generated the highest revenue?
4. Which products had the most returns?
5. Which month had the biggest revenue decline?
6. Which cities generated the highest revenue?
7. What is the total refund amount?
8. Which categories had the highest refund amount?

---

## Folder Structure

```text
GenAI_Business_Insight_Agent/
│
├── data/
│   ├── raw/
│   └── cleaned/
│
├── outputs/
│
├── sql/
│   ├── 01_create_tables.sql
│   └── 02_business_queries.sql
│
├── src/
│   ├── db.py
│   ├── gemini.py
│   ├── main.py
│   ├── python_analysis.py
│   ├── schema_context.py
│   └── sql_validator.py
│
├── .env
├── requirements.txt
└── README.md