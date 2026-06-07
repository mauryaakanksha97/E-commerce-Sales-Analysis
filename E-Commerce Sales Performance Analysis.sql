CREATE DATABASE IF NOT EXISTS india_ecommerce;
USE india_ecommerce;
SET FOREIGN_KEY_CHECKS = 0;
SET sql_mode = '';
-- STEP 1 : CREATE ALL 3 TABLES
-- ============================================================
DROP TABLE IF EXISTS order_details;
DROP TABLE IF EXISTS sales_target;
DROP TABLE IF EXISTS order_list;

-- Table 1: List of Orders
CREATE TABLE order_list (
    order_id      VARCHAR(20)  PRIMARY KEY,
    order_date    DATE,
    customer_name VARCHAR(100),
    state         VARCHAR(100),
    city          VARCHAR(100)
);
-- Table 2: Order Details
CREATE TABLE order_details (
    order_id      VARCHAR(20),
    amount        DECIMAL(10,2),
    profit        DECIMAL(10,2),
    quantity      INT,
    category      VARCHAR(100),
    sub_category  VARCHAR(100),
    payment_mode  VARCHAR(50),
    FOREIGN KEY (order_id) REFERENCES order_list(order_id)
);

-- Table 3: Sales Target
CREATE TABLE sales_target (
    month_of_order_date  VARCHAR(10),
    category             VARCHAR(100),
    target               DECIMAL(10,2),
    PRIMARY KEY (month_of_order_date, category)
);

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- STEP 3 : DATA QUALITY CHECKS
-- ============================================================

-- 3.1  Row counts across all 3 tables
SELECT 'order_list'    AS table_name, COUNT(*) AS total_rows FROM order_list
UNION ALL
SELECT 'order_details' AS table_name, COUNT(*) AS total_rows FROM order_details
UNION ALL
SELECT 'sales_target'  AS table_name, COUNT(*) AS total_rows FROM sales_target;

-- 3.2  Null checks on order_list
SELECT
    SUM(CASE WHEN order_id      IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN order_date    IS NULL THEN 1 ELSE 0 END) AS null_order_date,
    SUM(CASE WHEN customer_name IS NULL THEN 1 ELSE 0 END) AS null_customer,
    SUM(CASE WHEN state         IS NULL THEN 1 ELSE 0 END) AS null_state,
    SUM(CASE WHEN city          IS NULL THEN 1 ELSE 0 END) AS null_city
FROM order_list;

-- 3.3  Null checks on order_details
SELECT
    SUM(CASE WHEN order_id     IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN amount       IS NULL THEN 1 ELSE 0 END) AS null_amount,
    SUM(CASE WHEN profit       IS NULL THEN 1 ELSE 0 END) AS null_profit,
    SUM(CASE WHEN quantity     IS NULL THEN 1 ELSE 0 END) AS null_quantity,
    SUM(CASE WHEN category     IS NULL THEN 1 ELSE 0 END) AS null_category,
    SUM(CASE WHEN payment_mode IS NULL THEN 1 ELSE 0 END) AS null_payment
FROM order_details;

-- 3.4  Null checks on sales_target
SELECT
    SUM(CASE WHEN month_of_order_date IS NULL THEN 1 ELSE 0 END) AS null_month,
    SUM(CASE WHEN category            IS NULL THEN 1 ELSE 0 END) AS null_category,
    SUM(CASE WHEN target              IS NULL THEN 1 ELSE 0 END) AS null_target
FROM sales_target;

-- 3.5  Duplicate order IDs
SELECT order_id, COUNT(*) AS cnt
FROM order_list
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 3.6  Orphan rows in order_details (no matching order in order_list)
SELECT COUNT(*) AS orphan_rows
FROM order_details od
LEFT JOIN order_list ol 
ON od.order_id = ol.order_id
WHERE ol.order_id IS NULL;

-- 3.7  Date range of dataset
SELECT
    MIN(order_date) AS earliest_order,
    MAX(order_date) AS latest_order,
    DATEDIFF(MAX(order_date), MIN(order_date)) AS total_days
FROM order_list;

-- 3.8  Distinct values check
SELECT DISTINCT category, sub_category FROM order_details ORDER BY 1, 2;
SELECT DISTINCT payment_mode           FROM order_details ORDER BY 1;
SELECT DISTINCT category               FROM sales_target  ORDER BY 1;

-- 3.9  Negative or zero amount rows
SELECT COUNT(*) AS bad_amount_rows
FROM order_details
WHERE amount <= 0;

-- ============================================================
-- STEP 4 : OVERALL BUSINESS SUMMARY
-- ============================================================

SELECT
    COUNT(DISTINCT ol.order_id)                               AS total_orders,
    COUNT(DISTINCT ol.customer_name)                          AS unique_customers,
    COUNT(DISTINCT ol.state)                                  AS states_covered,
    COUNT(DISTINCT ol.city)                                   AS cities_covered,
    COUNT(DISTINCT od.category)                               AS product_categories,
    COUNT(DISTINCT od.sub_category)                           AS sub_categories,
    SUM(od.quantity)                                          AS total_units_sold,
    ROUND(SUM(od.amount), 2)                                  AS total_revenue,
    ROUND(SUM(od.profit), 2)                                  AS total_profit,
    ROUND(AVG(od.amount), 2)                                  AS avg_order_value,
    ROUND(SUM(od.profit) * 100.0
          / NULLIF(SUM(od.amount), 0), 2)                     AS overall_profit_margin_pct,
    SUM(CASE WHEN od.profit < 0 THEN 1 ELSE 0 END)            AS loss_making_orders
FROM order_list ol
JOIN order_details od ON ol.order_id = od.order_id;

-- ============================================================
-- STEP 5 : REVENUE & PROFIT TREND ANALYSIS
-- ============================================================

-- 5.1  Monthly revenue, profit and MoM growth
WITH monthly AS (
    SELECT
        DATE_FORMAT(ol.order_date, '%Y-%m-01')  AS order_month,
        ROUND(SUM(od.amount), 2)                AS total_revenue,
        ROUND(SUM(od.profit), 2)                AS total_profit,
        COUNT(DISTINCT ol.order_id)             AS total_orders,
        SUM(od.quantity)                        AS units_sold
    FROM order_list ol
    JOIN order_details od ON ol.order_id = od.order_id
    GROUP BY DATE_FORMAT(ol.order_date, '%Y-%m-01')
)
SELECT
    order_month,
    total_revenue,
    total_profit,
    total_orders,
    units_sold,
    ROUND(total_profit * 100.0
          / NULLIF(total_revenue, 0), 2)                    AS profit_margin_pct,
    LAG(total_revenue) OVER (ORDER BY order_month)          AS prev_month_revenue,
    ROUND(
        (total_revenue - LAG(total_revenue) OVER (ORDER BY order_month))
        * 100.0
        / NULLIF(LAG(total_revenue) OVER (ORDER BY order_month), 0)
    , 2)                                                    AS mom_revenue_growth_pct,
    ROUND(
        (total_profit - LAG(total_profit) OVER (ORDER BY order_month))
        * 100.0
        / NULLIF(LAG(total_profit) OVER (ORDER BY order_month), 0)
    , 2)                                                    AS mom_profit_growth_pct
FROM monthly
ORDER BY order_month;

-- 5.2  Quarterly revenue & profit summary
SELECT
    YEAR(ol.order_date)                              AS yr,
    QUARTER(ol.order_date)                           AS qtr,
    COUNT(DISTINCT ol.order_id)                      AS total_orders,
    ROUND(SUM(od.amount), 2)                         AS total_revenue,
    ROUND(SUM(od.profit), 2)                         AS total_profit,
    ROUND(SUM(od.profit) * 100.0
          / NULLIF(SUM(od.amount), 0), 2)             AS profit_margin_pct
FROM order_list ol
JOIN order_details od ON ol.order_id = od.order_id
GROUP BY YEAR(ol.order_date), QUARTER(ol.order_date)
ORDER BY yr, qtr;

-- 5.3  Day-of-week performance
SELECT
    DAYNAME(ol.order_date)                          AS day_of_week,
    DAYOFWEEK(ol.order_date)                        AS day_num,
    COUNT(DISTINCT ol.order_id)                     AS total_orders,
    ROUND(SUM(od.amount), 2)                        AS total_revenue,
    ROUND(SUM(od.profit), 2)                        AS total_profit,
    ROUND(AVG(od.amount), 2)                        AS avg_order_value
FROM order_list ol
JOIN order_details od ON ol.order_id = od.order_id
GROUP BY DAYNAME(ol.order_date), DAYOFWEEK(ol.order_date)
ORDER BY day_num;

-- 5.4  Running YTD cumulative revenue and profit
WITH daily AS (
    SELECT
        ol.order_date,
        ROUND(SUM(od.amount), 2) AS daily_revenue,
        ROUND(SUM(od.profit), 2) AS daily_profit
    FROM order_list ol
    JOIN order_details od ON ol.order_id = od.order_id
    GROUP BY ol.order_date
)
SELECT
    order_date,
    daily_revenue,
    daily_profit,
    SUM(daily_revenue) OVER (
        PARTITION BY YEAR(order_date)
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS ytd_revenue,
    SUM(daily_profit) OVER (
        PARTITION BY YEAR(order_date)
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS ytd_profit
FROM daily
ORDER BY order_date;

-- ============================================================
-- STEP 6 : SALES vs TARGET ANALYSIS
-- ===========================================================

-- 6.1  Actual sales vs target by month and category
WITH actual_sales AS (
    SELECT
        DATE_FORMAT(ol.order_date, '%b-%y')  AS sale_month,
        od.category,
        ROUND(SUM(od.amount), 2)             AS actual_revenue
    FROM order_list ol
    JOIN order_details od ON ol.order_id = od.order_id
    GROUP BY DATE_FORMAT(ol.order_date, '%b-%y'), od.category
)
SELECT
    st.month_of_order_date                             AS month,
    st.category,
    ROUND(st.target, 2)                                AS target_revenue,
    COALESCE(ac.actual_revenue, 0)                     AS actual_revenue,
    ROUND(COALESCE(ac.actual_revenue, 0)
          - st.target, 2)                              AS variance,
    ROUND((COALESCE(ac.actual_revenue, 0)
          - st.target) * 100.0
          / NULLIF(st.target, 0), 2)                   AS variance_pct,
    CASE
        WHEN COALESCE(ac.actual_revenue, 0) >= st.target THEN 'HIT ✓'
        ELSE 'MISS ✗'
    END                                                AS target_status
FROM sales_target st
LEFT JOIN actual_sales ac
       ON st.month_of_order_date = ac.sale_month
      AND st.category            = ac.category
ORDER BY st.month_of_order_date, st.category;

-- 6.2  How many times did each category HIT vs MISS target?
WITH actual_sales AS (
    SELECT
        DATE_FORMAT(ol.order_date, '%b-%y')  AS sale_month,
        od.category,
        ROUND(SUM(od.amount), 2)             AS actual_revenue
    FROM order_list ol
    JOIN order_details od ON ol.order_id = od.order_id
    GROUP BY DATE_FORMAT(ol.order_date, '%b-%y'), od.category
),
hit_miss AS (
    SELECT
        st.category,
        CASE
            WHEN COALESCE(ac.actual_revenue, 0) >= st.target THEN 'HIT'
            ELSE 'MISS'
        END AS status
    FROM sales_target st
    LEFT JOIN actual_sales ac
           ON st.month_of_order_date = ac.sale_month
          AND st.category            = ac.category
)
SELECT
    category,
    SUM(CASE WHEN status = 'HIT'  THEN 1 ELSE 0 END) AS months_hit,
    SUM(CASE WHEN status = 'MISS' THEN 1 ELSE 0 END) AS months_missed,
    COUNT(*)                                          AS total_months,
    ROUND(SUM(CASE WHEN status = 'HIT' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 2)                      AS hit_rate_pct
FROM hit_miss
GROUP BY category
ORDER BY hit_rate_pct DESC;

-- 6.3  Overall target achievement summary
WITH actual_sales AS (
    SELECT
        DATE_FORMAT(ol.order_date, '%b-%y')  AS sale_month,
        od.category,
        ROUND(SUM(od.amount), 2)             AS actual_revenue
    FROM order_list ol
    JOIN order_details od ON ol.order_id = od.order_id
    GROUP BY DATE_FORMAT(ol.order_date, '%b-%y'), od.category
)
SELECT
    ROUND(SUM(st.target), 2)                             AS total_target,
    ROUND(SUM(COALESCE(ac.actual_revenue, 0)), 2)        AS total_actual,
    ROUND(SUM(COALESCE(ac.actual_revenue, 0))
          - SUM(st.target), 2)                           AS total_variance,
    ROUND((SUM(COALESCE(ac.actual_revenue, 0))
          - SUM(st.target)) * 100.0
          / NULLIF(SUM(st.target), 0), 2)                AS overall_achievement_pct
FROM sales_target st
LEFT JOIN actual_sales ac
       ON st.month_of_order_date = ac.sale_month
      AND st.category            = ac.category;

-- 6.4  Best and worst months against target
WITH actual_sales AS (
    SELECT
        DATE_FORMAT(ol.order_date, '%b-%y')  AS sale_month,
        ROUND(SUM(od.amount), 2)             AS actual_revenue
    FROM order_list ol
    JOIN order_details od ON ol.order_id = od.order_id
    GROUP BY DATE_FORMAT(ol.order_date, '%b-%y')
),
monthly_target AS (
    SELECT
        month_of_order_date,
        SUM(target) AS total_target
    FROM sales_target
    GROUP BY month_of_order_date
)
SELECT
    mt.month_of_order_date                             AS month,
    ROUND(mt.total_target, 2)                          AS monthly_target,
    COALESCE(ac.actual_revenue, 0)                     AS actual_revenue,
    ROUND(COALESCE(ac.actual_revenue, 0)
          - mt.total_target, 2)                        AS variance,
    ROUND((COALESCE(ac.actual_revenue, 0)
          - mt.total_target) * 100.0
          / NULLIF(mt.total_target, 0), 2)             AS achievement_pct,
    RANK() OVER (ORDER BY
        (COALESCE(ac.actual_revenue, 0) - mt.total_target) DESC
    )                                                  AS best_month_rank
FROM monthly_target mt
LEFT JOIN actual_sales ac ON mt.month_of_order_date = ac.sale_month
ORDER BY achievement_pct DESC;

-- ============================================================
-- STEP 7 : CATEGORY & SUB-CATEGORY ANALYSIS
-- ============================================================

-- 7.1  Category performance — revenue, profit, margin
SELECT
    od.category,
    COUNT(DISTINCT ol.order_id)                          AS total_orders,
    SUM(od.quantity)                                     AS units_sold,
    ROUND(SUM(od.amount), 2)                             AS total_revenue,
    ROUND(SUM(od.profit), 2)                             AS total_profit,
    ROUND(AVG(od.amount), 2)                             AS avg_order_value,
    ROUND(SUM(od.profit) * 100.0
          / NULLIF(SUM(od.amount), 0), 2)                AS profit_margin_pct,
    ROUND(SUM(od.amount) * 100.0
          / SUM(SUM(od.amount)) OVER(), 2)               AS revenue_share_pct,
    DENSE_RANK() OVER (ORDER BY SUM(od.amount) DESC)     AS revenue_rank
FROM order_list ol
JOIN order_details od ON ol.order_id = od.order_id
GROUP BY od.category
ORDER BY total_revenue DESC;

-- 7.2  Sub-category deep dive
SELECT
    od.category,
    od.sub_category,
    COUNT(DISTINCT ol.order_id)                          AS total_orders,
    SUM(od.quantity)                                     AS units_sold,
    ROUND(SUM(od.amount), 2)                             AS total_revenue,
    ROUND(SUM(od.profit), 2)                             AS total_profit,
    ROUND(SUM(od.profit) * 100.0
          / NULLIF(SUM(od.amount), 0), 2)                AS profit_margin_pct,
    DENSE_RANK() OVER (ORDER BY SUM(od.profit) DESC)     AS profit_rank
FROM order_list ol
JOIN order_details od ON ol.order_id = od.order_id
GROUP BY od.category, od.sub_category
ORDER BY total_profit DESC;

-- 7.3  Loss-making sub-categories
SELECT
    od.category,
    od.sub_category,
    ROUND(SUM(od.amount), 2)       AS total_revenue,
    ROUND(SUM(od.profit), 2)       AS total_profit,
    COUNT(DISTINCT ol.order_id)    AS total_orders
FROM order_list ol
JOIN order_details od ON ol.order_id = od.order_id
GROUP BY od.category, od.sub_category
HAVING SUM(od.profit) < 0
ORDER BY total_profit ASC;

-- 7.4  Top 3 sub-categories per category by profit
WITH ranked_sub AS (
    SELECT
        od.category,
        od.sub_category,
        ROUND(SUM(od.profit), 2)  AS total_profit,
        DENSE_RANK() OVER (
            PARTITION BY od.category
            ORDER BY SUM(od.profit) DESC
        ) AS profit_rank
    FROM order_list ol
    JOIN order_details od ON ol.order_id = od.order_id
    GROUP BY od.category, od.sub_category
)
SELECT category, sub_category, total_profit, profit_rank
FROM ranked_sub
WHERE profit_rank <= 3
ORDER BY category, profit_rank;

-- 7.5  Pareto analysis — sub-categories driving 80% of revenue
WITH sub_revenue AS (
    SELECT
        od.category,
        od.sub_category,
        ROUND(SUM(od.amount), 2) AS revenue
    FROM order_list ol
    JOIN order_details od ON ol.order_id = od.order_id
    GROUP BY od.category, od.sub_category
),
ranked AS (
    SELECT *,
        SUM(revenue) OVER (
            ORDER BY revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_revenue,
        SUM(revenue) OVER () AS grand_total
    FROM sub_revenue
)
SELECT
    category,
    sub_category,
    revenue,
    ROUND(cumulative_revenue * 100.0 / grand_total, 2)  AS cumulative_pct,
    CASE
        WHEN cumulative_revenue * 100.0 / grand_total <= 80
        THEN 'Top 80% Revenue Drivers'
        ELSE 'Remaining 20%'
    END AS pareto_group
FROM ranked
ORDER BY revenue DESC;

-- ============================================================
-- STEP 8 : CUSTOMER ANALYSIS & RFM SEGMENTATION
-- ============================================================

-- 8.1  Top 10 customers by revenue
SELECT
    ol.customer_name,
    ol.state,
    ol.city,
    COUNT(DISTINCT ol.order_id)   AS total_orders,
    SUM(od.quantity)              AS total_units,
    ROUND(SUM(od.amount), 2)      AS total_spent,
    ROUND(SUM(od.profit), 2)      AS profit_generated,
    ROUND(AVG(od.amount), 2)      AS avg_order_value,
    MIN(ol.order_date)            AS first_purchase,
    MAX(ol.order_date)            AS last_purchase
FROM order_list ol
JOIN order_details od ON ol.order_id = od.order_id
GROUP BY ol.customer_name, ol.state, ol.city
ORDER BY total_spent DESC
LIMIT 10;

-- 8.2  New customer acquisition per month
WITH first_orders AS (
    SELECT
        customer_name,
        MIN(order_date) AS first_order_date
    FROM order_list
    GROUP BY customer_name
)
SELECT
    DATE_FORMAT(first_order_date, '%Y-%m-01')  AS acquisition_month,
    COUNT(*)                                   AS new_customers,
    SUM(COUNT(*)) OVER (
        ORDER BY DATE_FORMAT(first_order_date, '%Y-%m-01')
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                          AS cumulative_customers
FROM first_orders
GROUP BY DATE_FORMAT(first_order_date, '%Y-%m-01')
ORDER BY acquisition_month;

-- 8.3  RFM segmentation
WITH rfm_base AS (
    SELECT
        ol.customer_name,
        MAX(ol.order_date)               AS last_purchase_date,
        COUNT(DISTINCT ol.order_id)      AS frequency,
        ROUND(SUM(od.amount), 2)         AS monetary
    FROM order_list ol
    JOIN order_details od ON ol.order_id = od.order_id
    GROUP BY ol.customer_name
),
rfm_scores AS (
    SELECT
        customer_name,
        last_purchase_date,
        frequency,
        monetary,
        DATEDIFF((SELECT MAX(order_date) FROM order_list), last_purchase_date)             AS recency_days,
        NTILE(4) OVER (ORDER BY DATEDIFF('2019-03-31', last_purchase_date) ASC) AS r_score,
        NTILE(4) OVER (ORDER BY frequency DESC)                 AS f_score,
        NTILE(4) OVER (ORDER BY monetary DESC)                  AS m_score
    FROM rfm_base
)
SELECT
    customer_name,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    (r_score + f_score + m_score)                               AS rfm_total,
    CASE
        WHEN r_score = 4 AND f_score = 4 AND m_score = 4        THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3                      THEN 'Loyal Customers'
        WHEN r_score = 4 AND f_score <= 2                       THEN 'New Customers'
        WHEN r_score >= 3 AND f_score <= 2 AND m_score >= 3     THEN 'Potential Loyalists'
        WHEN r_score <= 2 AND f_score >= 3                      THEN 'At Risk'
        WHEN r_score = 1 AND f_score = 1                        THEN 'Lost'
        ELSE 'Needs Attention'
    END                                                         AS customer_segment
FROM rfm_scores
ORDER BY rfm_total DESC;

-- 8.4  RFM segment summary — count and revenue per segment
WITH rfm_base AS (
    SELECT
        ol.customer_name,
        MAX(ol.order_date)           AS last_purchase_date,
        COUNT(DISTINCT ol.order_id)  AS frequency,
        ROUND(SUM(od.amount), 2)     AS monetary
    FROM order_list ol
    JOIN order_details od ON ol.order_id = od.order_id
    GROUP BY ol.customer_name
),
rfm_scores AS (
    SELECT customer_name, monetary,
        NTILE(4) OVER (ORDER BY DATEDIFF('2019-03-31', last_purchase_date) ASC) AS r_score,
        NTILE(4) OVER (ORDER BY frequency DESC)  AS f_score,
        NTILE(4) OVER (ORDER BY monetary DESC)   AS m_score
    FROM rfm_base
),
segmented AS (
    SELECT *,
        CASE
            WHEN r_score = 4 AND f_score = 4 AND m_score = 4    THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3                  THEN 'Loyal Customers'
            WHEN r_score = 4 AND f_score <= 2                   THEN 'New Customers'
            WHEN r_score >= 3 AND f_score <= 2 AND m_score >= 3 THEN 'Potential Loyalists'
            WHEN r_score <= 2 AND f_score >= 3                  THEN 'At Risk'
            WHEN r_score = 1 AND f_score = 1                    THEN 'Lost'
            ELSE 'Needs Attention'
        END AS customer_segment
    FROM rfm_scores
)
SELECT
    customer_segment,
    COUNT(*)                                              AS customer_count,
    ROUND(SUM(monetary), 2)                               AS total_revenue,
    ROUND(AVG(monetary), 2)                               AS avg_spend,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)    AS pct_customers,
    ROUND(SUM(monetary) * 100.0
          / SUM(SUM(monetary)) OVER(), 2)                 AS pct_revenue
FROM segmented
GROUP BY customer_segment
ORDER BY total_revenue DESC;

-- ============================================================
-- STEP 9 : REGIONAL ANALYSIS
-- ============================================================

-- 9.1  Revenue and profit by state
SELECT
    ol.state,
    COUNT(DISTINCT ol.order_id)                               AS total_orders,
    COUNT(DISTINCT ol.customer_name)                          AS unique_customers,
    SUM(od.quantity)                                          AS units_sold,
    ROUND(SUM(od.amount), 2)                                  AS total_revenue,
    ROUND(SUM(od.profit), 2)                                  AS total_profit,
    ROUND(SUM(od.profit) * 100.0
          / NULLIF(SUM(od.amount), 0), 2)                     AS profit_margin_pct,
    ROUND(AVG(od.amount), 2)                                  AS avg_order_value,
    DENSE_RANK() OVER (ORDER BY SUM(od.amount) DESC)          AS revenue_rank,
    DENSE_RANK() OVER (ORDER BY SUM(od.profit) DESC)          AS profit_rank
FROM order_list ol
JOIN order_details od ON ol.order_id = od.order_id
GROUP BY ol.state
ORDER BY total_revenue DESC;

-- 9.2  Top 15 cities by revenue
SELECT
    ol.city,
    ol.state,
    COUNT(DISTINCT ol.order_id)              AS total_orders,
    COUNT(DISTINCT ol.customer_name)         AS unique_customers,
    ROUND(SUM(od.amount), 2)                 AS total_revenue,
    ROUND(SUM(od.profit), 2)                 AS total_profit,
    ROUND(AVG(od.amount), 2)                 AS avg_order_value,
    DENSE_RANK() OVER (ORDER BY SUM(od.amount) DESC) AS city_rank
FROM order_list ol
JOIN order_details od ON ol.order_id = od.order_id
GROUP BY ol.city, ol.state
ORDER BY total_revenue DESC
LIMIT 15;

-- 9.3  Top category per state
WITH state_category AS (
    SELECT
        ol.state,
        od.category,
        ROUND(SUM(od.amount), 2)  AS revenue,
        ROW_NUMBER() OVER (
            PARTITION BY ol.state
            ORDER BY SUM(od.amount) DESC
        ) AS rn
    FROM order_list ol
    JOIN order_details od ON ol.order_id = od.order_id
    GROUP BY ol.state, od.category
)
SELECT state, category AS top_category, revenue
FROM state_category
WHERE rn = 1
ORDER BY revenue DESC;

-- 9.4  First order date per state (market entry timeline)
WITH state_orders AS (
    SELECT
        ol.state,
        ol.order_date,
        ol.order_id,
        ol.customer_name,
        ol.city,
        ROW_NUMBER() OVER (
            PARTITION BY ol.state
            ORDER BY ol.order_date ASC
        ) AS rn
    FROM order_list ol
)
SELECT
    state,
    order_id,
    order_date      AS first_order_date,
    customer_name   AS first_customer,
    city            AS first_city
FROM state_orders
WHERE rn = 1
ORDER BY first_order_date;

-- ============================================================
-- STEP 10 : PAYMENT MODE ANALYSIS
-- ============================================================

-- 10.1  Revenue and orders by payment mode
SELECT
    od.payment_mode,
    COUNT(DISTINCT ol.order_id)                              AS total_orders,
    SUM(od.quantity)                                         AS units_sold,
    ROUND(SUM(od.amount), 2)                                 AS total_revenue,
    ROUND(SUM(od.profit), 2)                                 AS total_profit,
    ROUND(AVG(od.amount), 2)                                 AS avg_order_value,
    ROUND(COUNT(DISTINCT ol.order_id) * 100.0
          / SUM(COUNT(DISTINCT ol.order_id)) OVER(), 2)      AS pct_orders,
    ROUND(SUM(od.amount) * 100.0
          / SUM(SUM(od.amount)) OVER(), 2)                   AS pct_revenue
FROM order_list ol
JOIN order_details od ON ol.order_id = od.order_id
GROUP BY od.payment_mode
ORDER BY total_revenue DESC;

-- 10.2  Payment mode preference by state
SELECT
    ol.state,
    od.payment_mode,
    COUNT(DISTINCT ol.order_id)  AS orders,
    ROUND(SUM(od.amount), 2)     AS revenue,
    DENSE_RANK() OVER (
        PARTITION BY ol.state
        ORDER BY COUNT(DISTINCT ol.order_id) DESC
    )                            AS preference_rank
FROM order_list ol
JOIN order_details od ON ol.order_id = od.order_id
GROUP BY ol.state, od.payment_mode
ORDER BY ol.state, preference_rank;


-- 10.3  Top payment mode per category
WITH payment_category AS (
    SELECT
        od.category,
        od.payment_mode,
        COUNT(DISTINCT ol.order_id)  AS orders,
        ROW_NUMBER() OVER (
            PARTITION BY od.category
            ORDER BY COUNT(DISTINCT ol.order_id) DESC
        ) AS rn
    FROM order_list ol
    JOIN order_details od ON ol.order_id = od.order_id
    GROUP BY od.category, od.payment_mode
)
SELECT category, payment_mode AS preferred_payment_mode, orders
FROM payment_category
WHERE rn = 1
ORDER BY category;

-- ============================================================
-- STEP 11 : PROFITABILITY DEEP DIVE
-- ============================================================

-- 11.1  Profit margin ranking by sub-category
WITH profit_data AS (
    SELECT
        od.category,
        od.sub_category,
        ROUND(SUM(od.amount), 2)  AS revenue,
        ROUND(SUM(od.profit), 2)  AS profit,
        ROUND(SUM(od.profit) * 100.0
              / NULLIF(SUM(od.amount), 0), 2) AS margin_pct
    FROM order_list ol
    JOIN order_details od ON ol.order_id = od.order_id
    GROUP BY od.category, od.sub_category
)
SELECT *,
    DENSE_RANK() OVER (ORDER BY margin_pct DESC) AS margin_rank
FROM profit_data
ORDER BY margin_pct DESC;

-- 11.2  3-month moving average of profit
WITH monthly_profit AS (
    SELECT
        DATE_FORMAT(ol.order_date, '%Y-%m-01')  AS order_month,
        ROUND(SUM(od.profit), 2)                AS monthly_profit
    FROM order_list ol
    JOIN order_details od ON ol.order_id = od.order_id
    GROUP BY DATE_FORMAT(ol.order_date, '%Y-%m-01')
)
SELECT
    order_month,
    monthly_profit,
    ROUND(AVG(monthly_profit) OVER (
        ORDER BY order_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_3m
FROM monthly_profit
ORDER BY order_month;

-- 11.3  All loss-making orders
SELECT
    ol.order_id,
    ol.order_date,
    ol.customer_name,
    ol.state,
    ol.city,
    od.category,
    od.sub_category,
    od.payment_mode,
    ROUND(od.amount, 2)  AS revenue,
    ROUND(od.profit, 2)  AS profit,
    od.quantity
FROM order_list ol
JOIN order_details od ON ol.order_id = od.order_id
WHERE od.profit < 0
ORDER BY od.profit ASC;

-- 11.4  Loss summary
SELECT
    COUNT(*)                         AS loss_order_count,
    ROUND(SUM(od.amount), 2)         AS loss_order_revenue,
    ROUND(SUM(od.profit), 2)         AS total_loss,
    ROUND(ABS(SUM(od.profit)) * 100.0
          / (SELECT SUM(amount)
             FROM order_details), 2) AS loss_as_pct_of_revenue
FROM order_details od
WHERE od.profit < 0;

-- ============================================================
-- STEP 12 : CUSTOMER LIFETIME VALUE (CLV)
-- ============================================================

-- 12.1  CLV per customer with quartile
WITH clv_data AS (
    SELECT
        ol.customer_name,
        ol.state,
        ol.city,
        COUNT(DISTINCT ol.order_id)                       AS total_orders,
        ROUND(SUM(od.amount), 2)                          AS total_spent,
        ROUND(SUM(od.profit), 2)                          AS profit_generated,
        MIN(ol.order_date)                                AS first_order,
        MAX(ol.order_date)                                AS last_order,
        DATEDIFF(MAX(ol.order_date), MIN(ol.order_date))  AS lifespan_days,
        ROUND(AVG(od.amount), 2)                          AS avg_order_value
    FROM order_list ol
    JOIN order_details od ON ol.order_id = od.order_id
    GROUP BY ol.customer_name, ol.state, ol.city
)
SELECT *,
    NTILE(4) OVER (ORDER BY total_spent DESC)  AS clv_quartile,
    CASE NTILE(4) OVER (ORDER BY total_spent DESC)
        WHEN 1 THEN 'High Value'
        WHEN 2 THEN 'Mid-High Value'
        WHEN 3 THEN 'Mid-Low Value'
        ELSE        'Low Value'
    END AS clv_segment
FROM clv_data
ORDER BY total_spent DESC;

-- 12.2  CLV segment summary
WITH clv_data AS (
    SELECT
        ol.customer_name,
        ROUND(SUM(od.amount), 2)  AS total_spent
    FROM order_list ol
    JOIN order_details od ON ol.order_id = od.order_id
    GROUP BY ol.customer_name
),
clv_quartiles AS (
    SELECT *,
        NTILE(4) OVER (ORDER BY total_spent DESC) AS clv_quartile
    FROM clv_data
)
SELECT
    clv_quartile,
    CASE clv_quartile
        WHEN 1 THEN 'High Value'
        WHEN 2 THEN 'Mid-High Value'
        WHEN 3 THEN 'Mid-Low Value'
        ELSE        'Low Value'
    END                                                      AS segment,
    COUNT(*)                                                 AS customers,
    ROUND(SUM(total_spent), 2)                               AS total_revenue,
    ROUND(AVG(total_spent), 2)                               AS avg_clv,
    ROUND(SUM(total_spent) * 100.0
          / SUM(SUM(total_spent)) OVER(), 2)                 AS pct_revenue
FROM clv_quartiles
GROUP BY clv_quartile
ORDER BY clv_quartile;

-- ============================================================
-- STEP 13 : COHORT RETENTION ANALYSIS
-- ============================================================

WITH cohort_base AS (
    SELECT
        customer_name,
        DATE_FORMAT(MIN(order_date), '%Y-%m-01')  AS cohort_month
    FROM order_list
    GROUP BY customer_name
),
customer_activity AS (
    SELECT
        customer_name,
        DATE_FORMAT(order_date, '%Y-%m-01')  AS activity_month
    FROM order_list
    GROUP BY customer_name, DATE_FORMAT(order_date, '%Y-%m-01')
),
cohort_data AS (
    SELECT
        cb.cohort_month,
        ca.activity_month,
        COUNT(DISTINCT cb.customer_name)                         AS active_customers,
        TIMESTAMPDIFF(MONTH, cb.cohort_month, ca.activity_month) AS month_index
    FROM cohort_base cb
    JOIN customer_activity ca ON cb.customer_name = ca.customer_name
    GROUP BY cb.cohort_month, ca.activity_month
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(DISTINCT customer_name) AS cohort_size
    FROM cohort_base
    GROUP BY cohort_month
)
SELECT
    cd.cohort_month,
    cs.cohort_size,
    cd.month_index,
    cd.active_customers,
    ROUND(cd.active_customers * 100.0 / cs.cohort_size, 2) AS retention_rate_pct
FROM cohort_data cd
JOIN cohort_sizes cs ON cd.cohort_month = cs.cohort_month
WHERE cd.month_index BETWEEN 0 AND 11
ORDER BY cd.cohort_month, cd.month_index;

-- STEP 14 : ADVANCED WINDOW FUNCTION QUERIES
-- ============================================================

-- 14.1  Customer revenue leaderboard with rank within state
WITH customer_revenue AS (
    SELECT

        ol.customer_name,
        ol.state,
        ROUND(SUM(od.amount), 2)  AS total_revenue,
        ROUND(SUM(od.profit), 2)  AS total_profit
    FROM order_list ol
    JOIN order_details od ON ol.order_id = od.order_id
    GROUP BY ol.customer_name, ol.state
)
SELECT
    customer_name,
    state,
    total_revenue,
    total_profit,
    RANK()       OVER (ORDER BY total_revenue DESC)         AS overall_rank,
    DENSE_RANK() OVER (
        PARTITION BY state
        ORDER BY total_revenue DESC
    )                                                       AS rank_in_state,
    ROUND(total_revenue * 100.0
          / SUM(total_revenue) OVER(), 2)                   AS revenue_share_pct
FROM customer_revenue
ORDER BY overall_rank;

-- 14.2  Month-over-month revenue change per category
WITH cat_monthly AS (
    SELECT
        od.category,
        DATE_FORMAT(ol.order_date, '%Y-%m-01')  AS order_month,
        ROUND(SUM(od.amount), 2)                AS revenue
    FROM order_list ol
    JOIN order_details od ON ol.order_id = od.order_id
    GROUP BY od.category, DATE_FORMAT(ol.order_date, '%Y-%m-01')
)
SELECT
    category,
    order_month,
    revenue,
    LAG(revenue) OVER (PARTITION BY category ORDER BY order_month) AS prev_month,
    ROUND(
        (revenue - LAG(revenue) OVER (PARTITION BY category ORDER BY order_month))
        * 100.0
        / NULLIF(LAG(revenue) OVER (PARTITION BY category ORDER BY order_month), 0)
    , 2) AS mom_growth_pct
FROM cat_monthly
ORDER BY category, order_month;

-- 14.3  Histogram — orders per day of week (text based)
SELECT
    DAYNAME(order_date)                         AS day_name,
    COUNT(DISTINCT order_id)                    AS order_count,
    LPAD('*', COUNT(DISTINCT order_id), '*')    AS histogram
FROM order_list
GROUP BY DAYNAME(order_date), DAYOFWEEK(order_date)
ORDER BY DAYOFWEEK(order_date);


-- ============================================================
-- STEP 15 : EXECUTIVE SUMMARY VIEW
-- ============================================================

CREATE OR REPLACE VIEW v_executive_summary AS
SELECT
    DATE_FORMAT(ol.order_date, '%Y-%m-01')              AS month,
    COUNT(DISTINCT ol.order_id)                         AS total_orders,
    COUNT(DISTINCT ol.customer_name)                    AS unique_customers,
    COUNT(DISTINCT ol.state)                            AS active_states,
    SUM(od.quantity)                                    AS units_sold,
    ROUND(SUM(od.amount), 2)                            AS total_revenue,
    ROUND(SUM(od.profit), 2)                            AS total_profit,
    ROUND(AVG(od.amount), 2)                            AS avg_order_value,
    ROUND(SUM(od.profit) * 100.0
          / NULLIF(SUM(od.amount), 0), 2)               AS profit_margin_pct,
    SUM(CASE WHEN od.profit < 0 THEN 1 ELSE 0 END)      AS loss_orders
FROM order_list ol
JOIN order_details od ON ol.order_id = od.order_id
GROUP BY DATE_FORMAT(ol.order_date, '%Y-%m-01')
ORDER BY month;

-- Query the executive summary view
SELECT * FROM v_executive_summary;
