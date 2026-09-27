# GenAI Business Insight Agent

## Project Overview

The **GenAI Business Insight Agent** is an AI-powered analytics project built using **Python, PostgreSQL, SQL, Pandas, and the Gemini API**.

The main purpose of this project is to help business users ask questions in plain English and receive data-backed answers without manually writing SQL.

For example, a business user can ask:

- What is the total revenue?
- Which customers generated the highest revenue?
- Which categories performed best?
- Which products had the most returns?
- Which month had the biggest revenue decline?
- Which cities generated the highest revenue?
- What is the total refund amount?

The agent reads the real PostgreSQL schema, generates SQL using Gemini, validates the query for safety, executes it against PostgreSQL, and then explains the actual result in business language.

---

## Why I Built This Project

In real businesses, managers and stakeholders frequently ask ad-hoc questions that may not already exist in dashboards.

Normally, an analyst has to:

1. Understand the question
2. Write SQL manually
3. Execute the query
4. Validate the result
5. Explain the result to the stakeholder

This process can take time, especially when many ad-hoc questions are asked.

I built this project to demonstrate how **GenAI can assist the analytics workflow** while still keeping the final answer grounded in actual database results.

The project does not allow Gemini to directly modify the database. Python acts as the control layer between Gemini and PostgreSQL.

---

## Business Objective

The main business objective was to create a system that can:

- Understand natural-language business questions
- Convert those questions into PostgreSQL SQL
- Use the actual database schema
- Prevent destructive SQL
- Execute only approved read-only queries
- Return verified query results
- Convert technical results into business insights
- Provide practical recommendations

---

## Dataset

The project uses a relational retail dataset containing hundreds of thousands of transactional records.

The main tables used in the project are:

- `customers`
- `orders`
- `order_items`
- `products`
- `categories`
- `payments`
- `returns`

The dataset supports analysis across:

- Revenue
- Orders
- Customers
- Product categories
- Product performance
- Returns
- Refunds
- Customer location
- Monthly trends

---

## Technology Stack

- **Python**
- **Pandas**
- **PostgreSQL**
- **SQL**
- **Gemini API**
- **psycopg2**
- **python-dotenv**

---

## Project Architecture

```text
Business User
     |
     v
Natural-Language Question
     |
     v
Python Application
     |
     v
Read PostgreSQL Schema
     |
     v
Gemini API
     |
     v
Generate SQL
     |
     v
SQL Safety Validator
     |
     v
PostgreSQL
     |
     v
Actual Query Result
     |
     v
Gemini Business Explanation
     |
     v
Business Insight + Recommendation
