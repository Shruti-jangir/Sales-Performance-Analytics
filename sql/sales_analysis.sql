-- =============================================================================
--  Sales Performance Analytics — SQL Analysis Queries
--  Database: sales_db  |  Table: sales_orders
--  Author: Shruti Jangir
-- =============================================================================

-- ── 0. CREATE TABLE ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS sales_orders (
    order_id          VARCHAR(12)    PRIMARY KEY,
    order_date        DATE,
    ship_date         DATE,
    year              INT,
    quarter           VARCHAR(2),
    month             INT,
    month_name        VARCHAR(12),
    customer_name     VARCHAR(100),
    customer_segment  VARCHAR(20),
    region            VARCHAR(20),
    city              VARCHAR(50),
    sales_rep         VARCHAR(60),
    product_name      VARCHAR(80),
    product_category  VARCHAR(30),
    quantity          INT,
    unit_price        DECIMAL(12,2),
    discount_pct      DECIMAL(5,2),
    unit_revenue      DECIMAL(12,2),
    unit_cost         DECIMAL(12,2),
    revenue           DECIMAL(14,2),
    cogs              DECIMAL(14,2),
    gross_profit      DECIMAL(14,2),
    margin_pct        DECIMAL(6,2),
    shipping_days     INT,
    order_status      VARCHAR(20),
    sales_channel     VARCHAR(30),
    payment_method    VARCHAR(30),
    customer_rating   DECIMAL(3,1)
);

-- =============================================================================
--  SECTION 1 – OVERALL KPIs
-- =============================================================================

-- 1.1  Top-level business KPIs
SELECT
    COUNT(DISTINCT order_id)                         AS total_orders,
    COUNT(DISTINCT customer_name)                    AS unique_customers,
    ROUND(SUM(revenue), 0)                           AS total_revenue,
    ROUND(SUM(gross_profit), 0)                      AS total_gross_profit,
    ROUND(AVG(margin_pct), 2)                        AS avg_margin_pct,
    ROUND(SUM(revenue) / COUNT(DISTINCT order_id),0) AS avg_order_value,
    ROUND(AVG(customer_rating), 2)                   AS avg_customer_rating
FROM sales_orders
WHERE order_status = 'Completed';


-- 1.2  YoY revenue comparison
SELECT
    year,
    COUNT(order_id)         AS orders,
    ROUND(SUM(revenue), 0)  AS revenue,
    ROUND(SUM(gross_profit),0) AS gross_profit,
    ROUND(AVG(margin_pct), 2)  AS avg_margin_pct
FROM sales_orders
WHERE order_status = 'Completed'
GROUP BY year
ORDER BY year;


-- =============================================================================
--  SECTION 2 – REVENUE TRENDS
-- =============================================================================

-- 2.1  Monthly revenue trend (all years)
SELECT
    year,
    month,
    month_name,
    ROUND(SUM(revenue), 0)      AS monthly_revenue,
    ROUND(SUM(gross_profit), 0) AS monthly_profit,
    COUNT(order_id)             AS order_count
FROM sales_orders
WHERE order_status = 'Completed'
GROUP BY year, month, month_name
ORDER BY year, month;


-- 2.2  Quarterly performance
SELECT
    year,
    quarter,
    ROUND(SUM(revenue), 0)      AS quarterly_revenue,
    ROUND(SUM(gross_profit), 0) AS quarterly_profit,
    ROUND(AVG(margin_pct), 2)   AS avg_margin,
    COUNT(order_id)             AS orders
FROM sales_orders
WHERE order_status = 'Completed'
GROUP BY year, quarter
ORDER BY year, quarter;


-- 2.3  Trailing 12-month revenue (rolling window)
SELECT
    order_date,
    revenue,
    SUM(revenue) OVER (
        ORDER BY order_date
        ROWS BETWEEN 364 PRECEDING AND CURRENT ROW
    ) AS trailing_12m_revenue
FROM sales_orders
WHERE order_status = 'Completed'
ORDER BY order_date;


-- =============================================================================
--  SECTION 3 – PRODUCT ANALYSIS
-- =============================================================================

-- 3.1  Revenue & profit by product category
SELECT
    product_category,
    COUNT(order_id)             AS orders,
    SUM(quantity)               AS units_sold,
    ROUND(SUM(revenue), 0)      AS total_revenue,
    ROUND(SUM(gross_profit), 0) AS total_profit,
    ROUND(AVG(margin_pct), 2)   AS avg_margin_pct,
    ROUND(SUM(revenue) * 100.0 /
          SUM(SUM(revenue)) OVER (), 2) AS revenue_share_pct
FROM sales_orders
WHERE order_status = 'Completed'
GROUP BY product_category
ORDER BY total_revenue DESC;


-- 3.2  Top 10 products by revenue
SELECT
    product_name,
    product_category,
    SUM(quantity)               AS units_sold,
    ROUND(SUM(revenue), 0)      AS total_revenue,
    ROUND(SUM(gross_profit), 0) AS total_profit,
    ROUND(AVG(margin_pct), 2)   AS avg_margin_pct,
    ROUND(AVG(unit_price), 0)   AS avg_selling_price
FROM sales_orders
WHERE order_status = 'Completed'
GROUP BY product_name, product_category
ORDER BY total_revenue DESC
LIMIT 10;


-- 3.3  Products with highest margin (min 50 orders)
SELECT
    product_name,
    product_category,
    COUNT(order_id)           AS order_count,
    ROUND(AVG(margin_pct), 2) AS avg_margin_pct,
    ROUND(SUM(revenue), 0)    AS total_revenue
FROM sales_orders
WHERE order_status = 'Completed'
GROUP BY product_name, product_category
HAVING COUNT(order_id) >= 50
ORDER BY avg_margin_pct DESC
LIMIT 10;


-- =============================================================================
--  SECTION 4 – REGIONAL ANALYSIS
-- =============================================================================

-- 4.1  Performance by region
SELECT
    region,
    COUNT(DISTINCT customer_name)   AS unique_customers,
    COUNT(order_id)                 AS total_orders,
    ROUND(SUM(revenue), 0)          AS total_revenue,
    ROUND(SUM(gross_profit), 0)     AS total_profit,
    ROUND(AVG(margin_pct), 2)       AS avg_margin_pct,
    ROUND(AVG(customer_rating), 2)  AS avg_rating,
    ROUND(SUM(revenue) * 100.0 /
          SUM(SUM(revenue)) OVER (), 2) AS revenue_share_pct
FROM sales_orders
WHERE order_status = 'Completed'
GROUP BY region
ORDER BY total_revenue DESC;


-- 4.2  Top 5 cities by revenue
SELECT
    city,
    region,
    COUNT(order_id)             AS orders,
    ROUND(SUM(revenue), 0)      AS revenue,
    ROUND(SUM(gross_profit), 0) AS profit
FROM sales_orders
WHERE order_status = 'Completed'
GROUP BY city, region
ORDER BY revenue DESC
LIMIT 5;


-- =============================================================================
--  SECTION 5 – SALES REP PERFORMANCE
-- =============================================================================

-- 5.1  Rep leaderboard
SELECT
    sales_rep,
    region,
    COUNT(order_id)                                     AS total_orders,
    ROUND(SUM(revenue), 0)                              AS total_revenue,
    ROUND(SUM(gross_profit), 0)                         AS total_profit,
    ROUND(AVG(margin_pct), 2)                           AS avg_margin,
    ROUND(AVG(customer_rating), 2)                      AS avg_rating,
    RANK() OVER (ORDER BY SUM(revenue) DESC)            AS revenue_rank
FROM sales_orders
WHERE order_status = 'Completed'
GROUP BY sales_rep, region
ORDER BY total_revenue DESC;


-- 5.2  Rep performance vs region average
WITH rep_stats AS (
    SELECT
        sales_rep, region,
        ROUND(SUM(revenue), 0)    AS rep_revenue,
        ROUND(AVG(margin_pct), 2) AS rep_margin
    FROM sales_orders
    WHERE order_status = 'Completed'
    GROUP BY sales_rep, region
),
region_avg AS (
    SELECT region,
        ROUND(AVG(rep_revenue), 0)    AS region_avg_revenue,
        ROUND(AVG(rep_margin), 2)     AS region_avg_margin
    FROM rep_stats
    GROUP BY region
)
SELECT
    r.sales_rep,
    r.region,
    r.rep_revenue,
    ra.region_avg_revenue,
    ROUND((r.rep_revenue - ra.region_avg_revenue) * 100.0
          / ra.region_avg_revenue, 1)                    AS pct_vs_region_avg,
    r.rep_margin,
    ra.region_avg_margin
FROM rep_stats r
JOIN region_avg ra ON r.region = ra.region
ORDER BY pct_vs_region_avg DESC;


-- =============================================================================
--  SECTION 6 – CUSTOMER ANALYSIS
-- =============================================================================

-- 6.1  Revenue by customer segment
SELECT
    customer_segment,
    COUNT(DISTINCT customer_name)   AS unique_customers,
    COUNT(order_id)                 AS orders,
    ROUND(SUM(revenue), 0)          AS total_revenue,
    ROUND(AVG(revenue), 0)          AS avg_order_value,
    ROUND(AVG(margin_pct), 2)       AS avg_margin_pct,
    ROUND(AVG(customer_rating), 2)  AS avg_rating
FROM sales_orders
WHERE order_status = 'Completed'
GROUP BY customer_segment
ORDER BY total_revenue DESC;


-- 6.2  Top 10 customers by revenue (LTV proxy)
SELECT
    customer_name,
    customer_segment,
    region,
    COUNT(order_id)             AS order_count,
    ROUND(SUM(revenue), 0)      AS lifetime_revenue,
    ROUND(SUM(gross_profit), 0) AS lifetime_profit,
    ROUND(AVG(customer_rating),2) AS avg_rating
FROM sales_orders
WHERE order_status = 'Completed'
GROUP BY customer_name, customer_segment, region
ORDER BY lifetime_revenue DESC
LIMIT 10;


-- =============================================================================
--  SECTION 7 – CHANNEL & OPERATIONAL METRICS
-- =============================================================================

-- 7.1  Revenue by sales channel
SELECT
    sales_channel,
    COUNT(order_id)             AS orders,
    ROUND(SUM(revenue), 0)      AS total_revenue,
    ROUND(AVG(revenue), 0)      AS avg_order_value,
    ROUND(AVG(margin_pct), 2)   AS avg_margin_pct
FROM sales_orders
WHERE order_status = 'Completed'
GROUP BY sales_channel
ORDER BY total_revenue DESC;


-- 7.2  Order status breakdown
SELECT
    order_status,
    COUNT(order_id)          AS orders,
    ROUND(SUM(revenue), 0)   AS impacted_revenue,
    ROUND(COUNT(order_id) * 100.0 /
          SUM(COUNT(order_id)) OVER (), 2) AS pct_of_total
FROM sales_orders
GROUP BY order_status
ORDER BY orders DESC;


-- 7.3  Discount impact on margin
SELECT
    discount_pct,
    COUNT(order_id)           AS orders,
    ROUND(AVG(margin_pct), 2) AS avg_margin_pct,
    ROUND(SUM(revenue), 0)    AS total_revenue
FROM sales_orders
WHERE order_status = 'Completed'
GROUP BY discount_pct
ORDER BY discount_pct;


-- 7.4  Average shipping time by region
SELECT
    region,
    ROUND(AVG(shipping_days), 1) AS avg_shipping_days,
    MIN(shipping_days)           AS min_days,
    MAX(shipping_days)           AS max_days
FROM sales_orders
WHERE order_status = 'Completed'
GROUP BY region
ORDER BY avg_shipping_days;
