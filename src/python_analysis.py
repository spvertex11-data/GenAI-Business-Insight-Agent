# ============================================
# PYTHON / PANDAS BUSINESS ANALYSIS
# ============================================

import pandas as pd
from db import get_connection


def monthly_revenue_analysis():
    """
    Read monthly revenue from PostgreSQL
    and calculate month-over-month change using Pandas.
    """

    conn = get_connection()

    query = """
    SELECT
        DATE_TRUNC('month', o.order_date) AS month,
        SUM(oi.qty * oi.price) AS revenue
    FROM analytics.orders o
    JOIN analytics.order_items oi
        ON o.order_id = oi.order_id
    GROUP BY month
    ORDER BY month;
    """

    df = pd.read_sql(query, conn)

    conn.close()

    # Previous month's revenue
    df["previous_month_revenue"] = df["revenue"].shift(1)

    # Revenue change
    df["revenue_change"] = (
        df["revenue"] - df["previous_month_revenue"]
    )

    # Revenue change percentage
    df["revenue_change_pct"] = (
        df["revenue_change"]
        / df["previous_month_revenue"]
        * 100
    )

    return df


def biggest_revenue_decline():
    """
    Find the month with the biggest revenue decline.
    """

    df = monthly_revenue_analysis()

    # Remove the first month because it has no previous month
    df = df.dropna(subset=["revenue_change"])

    # Lowest revenue change = biggest decline
    biggest_decline = df.sort_values(
        "revenue_change"
    ).head(1)

    return biggest_decline


def category_revenue_analysis():
    """
    Calculate category revenue and revenue share.
    """

    conn = get_connection()

    query = """
    SELECT
        c.category_name,
        SUM(oi.qty * oi.price) AS revenue
    FROM analytics.order_items oi
    JOIN analytics.products p
        ON oi.product_id = p.product_id
    JOIN analytics.categories c
        ON p.category_id = c.category_id
    GROUP BY c.category_name;
    """

    df = pd.read_sql(query, conn)

    conn.close()

    # Sort highest revenue categories first
    df = df.sort_values(
        "revenue",
        ascending=False
    )

    # Calculate each category's contribution
    df["revenue_share_pct"] = (
        df["revenue"]
        / df["revenue"].sum()
        * 100
    )

    return df


def return_refund_analysis():
    """
    Analyze returns and refund amounts by product.
    """

    conn = get_connection()

    query = """
    SELECT
        oi.product_id,
        COUNT(r.return_id) AS total_returns,
        SUM(r.refund) AS total_refund
    FROM analytics.returns r
    JOIN analytics.order_items oi
        ON r.order_item_id = oi.order_item_id
    GROUP BY oi.product_id;
    """

    df = pd.read_sql(query, conn)

    conn.close()

    # Sort by highest refund amount
    df = df.sort_values(
        "total_refund",
        ascending=False
    )

    return df


# ============================================
# RUN / TEST ALL PYTHON ANALYSIS
# ============================================

if __name__ == "__main__":

    # ----------------------------------------
    # 1. Monthly Revenue Analysis
    # ----------------------------------------

    print("\nMONTHLY REVENUE ANALYSIS")
    print("=" * 60)

    monthly_df = monthly_revenue_analysis()

    print(monthly_df)


    # ----------------------------------------
    # 2. Biggest Revenue Decline
    # ----------------------------------------

    print("\nBIGGEST REVENUE DECLINE")
    print("=" * 60)

    decline_df = biggest_revenue_decline()

    print(decline_df)


    # ----------------------------------------
    # 3. Category Revenue Analysis
    # ----------------------------------------

    print("\nCATEGORY REVENUE ANALYSIS")
    print("=" * 60)

    category_df = category_revenue_analysis()

    print(category_df.head(10))


    # ----------------------------------------
    # 4. Returns & Refund Analysis
    # ----------------------------------------

    print("\nRETURN & REFUND ANALYSIS")
    print("=" * 60)

    return_df = return_refund_analysis()

    print(return_df.head(10))