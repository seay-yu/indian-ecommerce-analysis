-- ============================================
-- 项目：印度电商数据分析项目
-- 文件：03_analytical_queries.sql
-- 用途：四大板块分析核心 SQL 查询
--       板块一：交易表现分析
--       板块二：客户结构分析
--       板块三：履约效率分析
--       板块四：售后质量分析
-- 数据库：indian_ecommerce_project
-- 作者：彭显余 (GitHub: seay-yu)
-- 创建时间：2026-08-29
-- 更新时间：2026-08-30
-- 注意事项：
--   1. 需在 01_schema.sql 和 02_data_cleaning.sql 执行成功后运行
--   2. 各查询均可独立运行，按板块顺序执行即可
--   3. 涉及日期计算，CURDATE() 会基于当前系统日期动态计算
-- ============================================

USE indian_ecommerce_project;


-- ============================================
-- 板块一：交易表现分析
-- 业务目标：回答 CEO 问题“增长主要来自量还是价？”
-- ============================================

-- 1.1 月度销售趋势（拆解订单量、销售额、客单价、人均消费）
SELECT 
    DATE_FORMAT(Order_Date, '%Y-%m') AS month,
    COUNT(DISTINCT Order_ID) AS order_count,
    ROUND(SUM(Total_Amount), 2) AS revenue,
    ROUND(AVG(Total_Amount), 2) AS avg_order_value,
    ROUND(SUM(Total_Amount) / NULLIF(COUNT(DISTINCT Customer_ID), 0), 2) AS revenue_per_customer
FROM sales
WHERE Order_Date IS NOT NULL
GROUP BY month
ORDER BY month;

-- 1.2 各邦销售额排名（Top 10）
SELECT 
    State,
    COUNT(DISTINCT Order_ID) AS order_count,
    ROUND(SUM(Total_Amount), 2) AS revenue,
    ROUND(SUM(Total_Amount) / (SELECT SUM(Total_Amount) FROM sales) * 100, 2) AS revenue_share_pct,
    ROUND(AVG(Total_Amount), 2) AS avg_order_value
FROM sales
WHERE State IS NOT NULL
GROUP BY State
ORDER BY revenue DESC
LIMIT 10;

-- 1.3 客单价分层分布
SELECT 
    CASE 
        WHEN Total_Amount <= 1000 THEN '低客单（≤1K）'
        WHEN Total_Amount <= 5000 THEN '中低客单（1K-5K）'
        WHEN Total_Amount <= 10000 THEN '中高客单（5K-1W）'
        ELSE '高客单（>1W）'
    END AS order_segment,
    COUNT(*) AS order_count,
    ROUND(SUM(Total_Amount), 2) AS revenue,
    ROUND(AVG(Total_Amount), 2) AS avg_order_value
FROM sales
GROUP BY order_segment
ORDER BY avg_order_value;


-- ============================================
-- 板块二：客户结构分析
-- 业务目标：回答 CEO 问题“Platinum 客户值得维护吗？”
-- ============================================

-- 2.1 各月新增客户数
WITH first_purchase AS (
    SELECT 
        Customer_ID,
        MIN(Order_Date) AS first_order_date
    FROM sales
    GROUP BY Customer_ID
)
SELECT 
    DATE_FORMAT(first_order_date, '%Y-%m') AS cohort_month,
    COUNT(DISTINCT Customer_ID) AS new_customers
FROM first_purchase
WHERE first_order_date IS NOT NULL
GROUP BY cohort_month
ORDER BY cohort_month;

-- 2.2 客户消费分层
WITH customer_monetary AS (
    SELECT 
        Customer_ID,
        ROUND(SUM(Total_Amount), 2) AS total_spent
    FROM sales
    GROUP BY Customer_ID
)
SELECT 
    CASE 
        WHEN total_spent <= 10000 THEN '低消费（≤1W）'
        WHEN total_spent <= 50000 THEN '中低消费（1W-5W）'
        WHEN total_spent <= 100000 THEN '中高消费（5W-10W）'
        ELSE '高消费（>10W）'
    END AS customer_segment,
    COUNT(*) AS customer_count
FROM customer_monetary
GROUP BY customer_segment
ORDER BY MIN(total_spent);

-- 2.3 客户购买频次分布
WITH customer_freq AS (
    SELECT 
        Customer_ID,
        COUNT(DISTINCT Order_ID) AS order_count
    FROM sales
    GROUP BY Customer_ID
)
SELECT 
    order_count,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM customer_freq) * 100, 2) AS pct
FROM customer_freq
GROUP BY order_count
ORDER BY order_count;

-- 2.4 各等级客户复购表现
SELECT 
    c.Customer_Tier,
    COUNT(DISTINCT c.Customer_ID) AS customer_count,
    COUNT(DISTINCT CASE WHEN s.Order_ID IS NOT NULL THEN c.Customer_ID END) AS active_customers,
    ROUND(COUNT(DISTINCT CASE WHEN s.Order_ID IS NOT NULL THEN c.Customer_ID END) / COUNT(DISTINCT c.Customer_ID) * 100, 2) AS active_rate_pct,
    COUNT(s.Order_ID) AS total_orders,
    ROUND(COUNT(s.Order_ID) / COUNT(DISTINCT c.Customer_ID), 2) AS avg_orders_per_customer
FROM customers c
LEFT JOIN sales s ON c.Customer_ID = s.Customer_ID
GROUP BY c.Customer_Tier
ORDER BY avg_orders_per_customer DESC;

-- 2.5 各等级客户销售贡献（核心查询）
SELECT 
    c.Customer_Tier,
    COUNT(DISTINCT c.Customer_ID) AS customer_count,
    ROUND(COUNT(DISTINCT c.Customer_ID) / (SELECT COUNT(*) FROM customers) * 100, 2) AS customer_pct,
    COUNT(DISTINCT s.Order_ID) AS order_count,
    ROUND(SUM(s.Total_Amount), 2) AS total_revenue,
    ROUND(SUM(s.Total_Amount) / (SELECT SUM(Total_Amount) FROM sales) * 100, 2) AS revenue_share_pct,
    ROUND(AVG(s.Total_Amount), 2) AS avg_order_value,
    ROUND(SUM(s.Total_Amount) / COUNT(DISTINCT c.Customer_ID), 2) AS revenue_per_customer
FROM customers c
LEFT JOIN sales s ON c.Customer_ID = s.Customer_ID
GROUP BY c.Customer_Tier
ORDER BY total_revenue DESC;


-- ============================================
-- 板块三：履约效率分析
-- 业务目标：回答 CEO 问题“物流升级有效吗？”
-- ============================================

-- 3.1 整体物流概况
SELECT 
    ROUND(AVG(DATEDIFF(Delivery_Date, Order_Date)), 2) AS avg_delivery_days,
    MIN(DATEDIFF(Delivery_Date, Order_Date)) AS min_delivery_days,
    MAX(DATEDIFF(Delivery_Date, Order_Date)) AS max_delivery_days,
    COUNT(CASE WHEN DATEDIFF(Delivery_Date, Order_Date) > 7 THEN 1 END) AS delayed_orders,
    ROUND(COUNT(CASE WHEN DATEDIFF(Delivery_Date, Order_Date) > 7 THEN 1 END) / COUNT(*) * 100, 2) AS delayed_rate_pct
FROM sales
WHERE Order_Date IS NOT NULL AND Delivery_Date IS NOT NULL;

-- 3.2 各邦物流时效排名
SELECT 
    State,
    COUNT(*) AS order_count,
    ROUND(AVG(DATEDIFF(Delivery_Date, Order_Date)), 2) AS avg_delivery_days,
    ROUND(SUM(Total_Amount), 2) AS total_revenue,
    COUNT(CASE WHEN DATEDIFF(Delivery_Date, Order_Date) > 7 THEN 1 END) AS delayed_orders,
    ROUND(COUNT(CASE WHEN DATEDIFF(Delivery_Date, Order_Date) > 7 THEN 1 END) / COUNT(*) * 100, 2) AS delayed_rate_pct
FROM sales
WHERE Order_Date IS NOT NULL AND Delivery_Date IS NOT NULL
GROUP BY State
HAVING order_count >= 50
ORDER BY avg_delivery_days DESC;

-- 3.3 各城市物流时效排名（Top 20）
SELECT 
    State,
    City,
    COUNT(*) AS order_count,
    ROUND(AVG(DATEDIFF(Delivery_Date, Order_Date)), 2) AS avg_delivery_days,
    ROUND(SUM(Total_Amount), 2) AS total_revenue,
    COUNT(CASE WHEN DATEDIFF(Delivery_Date, Order_Date) > 7 THEN 1 END) AS delayed_orders
FROM sales
WHERE Order_Date IS NOT NULL AND Delivery_Date IS NOT NULL
GROUP BY State, City
HAVING order_count >= 20
ORDER BY avg_delivery_days DESC
LIMIT 20;

-- 3.4 配送时效与评分关联
SELECT 
    CASE 
        WHEN DATEDIFF(Delivery_Date, Order_Date) <= 3 THEN '快速（1-3天）'
        WHEN DATEDIFF(Delivery_Date, Order_Date) <= 7 THEN '正常（4-7天）'
        ELSE '延迟（>7天）'
    END AS delivery_category,
    COUNT(*) AS order_count,
    ROUND(AVG(Rating), 2) AS avg_rating,
    ROUND(AVG(Total_Amount), 2) AS avg_order_value
FROM sales
WHERE Order_Date IS NOT NULL 
  AND Delivery_Date IS NOT NULL
  AND Rating IS NOT NULL
GROUP BY delivery_category
ORDER BY avg_rating DESC;


-- ============================================
-- 板块四：售后质量分析
-- 业务目标：回答 CEO 问题“客户满意度下滑了吗？”
-- ============================================

-- 4.1 评分整体分布
SELECT 
    Rating,
    COUNT(*) AS count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM sales WHERE Rating IS NOT NULL) * 100, 2) AS pct
FROM sales
WHERE Rating IS NOT NULL
GROUP BY Rating
ORDER BY Rating DESC;

-- 4.2 月度评分趋势
SELECT 
    DATE_FORMAT(Order_Date, '%Y-%m') AS month,
    ROUND(AVG(Rating), 2) AS avg_rating,
    COUNT(*) AS review_count
FROM sales
WHERE Rating IS NOT NULL AND Order_Date IS NOT NULL
GROUP BY month
ORDER BY month;

-- 4.3 评分与客单价、运费关联
SELECT
    CASE
        WHEN s.Rating <= 2 THEN '低评分 (1-2分)'
        WHEN s.Rating <= 3 THEN '中评分 (3分)'
        ELSE '高评分 (4-5分)'
    END AS rating_group,
    COUNT(*) AS order_count,
    ROUND(AVG(s.Total_Amount), 2) AS avg_order_value,
    ROUND(AVG(s.Shipping_Cost), 2) AS avg_shipping_cost
FROM sales s
WHERE s.Rating IS NOT NULL
GROUP BY rating_group
ORDER BY MIN(s.Rating);   

-- 4.4 低评分订单按品类分布
SELECT 
    p.Category,
    COUNT(s.Order_ID) AS low_rating_count,
    ROUND(AVG(s.Rating), 2) AS avg_rating
FROM sales s
JOIN products p ON s.Product_ID = p.Product_ID
WHERE s.Rating <= 2
GROUP BY p.Category
ORDER BY low_rating_count DESC;
