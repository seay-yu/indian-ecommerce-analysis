-- ============================================
-- 项目：印度电商数据分析项目
-- 文件：03_analytical_queries.sql
-- 用途：三条分析链路的核心 SQL 查询
-- 数据库：indian_ecommerce_project
-- 作者：[彭显余]
-- 创建时间：2026-08-29
-- 注意事项：
--   1. 需在 01_schema.sql 和 02_data_cleaning.sql 执行成功后运行
--   2. 按链路顺序逐条执行，每条查询均可独立运行
--   3. 涉及日期计算，CURDATE() 会基于当前系统日期动态计算
-- ============================================

USE indian_ecommerce_project;


-- ============================================
-- 链路一：物流效率瓶颈定位
-- 业务目标：识别配送时效过长的区域，分析其对客户满意度的影响
-- ============================================
USE indian_ecommerce_project;
-- 1.1 整体物流概况
-- 业务目的：了解平台整体配送效率，计算平均时效、延迟订单占比
SELECT 
    ROUND(AVG(DATEDIFF(Delivery_Date, Order_Date)), 2) AS avg_delivery_days,
    MIN(DATEDIFF(Delivery_Date, Order_Date)) AS min_delivery_days,
    MAX(DATEDIFF(Delivery_Date, Order_Date)) AS max_delivery_days,
    COUNT(CASE WHEN DATEDIFF(Delivery_Date, Order_Date) > 7 THEN 1 END) AS delayed_orders,
    ROUND(COUNT(CASE WHEN DATEDIFF(Delivery_Date, Order_Date) > 7 THEN 1 END) / COUNT(*) * 100, 2) AS delayed_rate_pct
FROM sales
WHERE Order_Date IS NOT NULL AND Delivery_Date IS NOT NULL;


-- 1.2 按邦（State）统计物流表现
-- 业务目的：定位物流表现较差的问题区域，为运营优化提供依据
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


-- 1.3 按城市（City）细分（精准定位 Top 20）
-- 业务目的：在城市级别精确定位物流效率最差的区域
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


-- 1.4 物流延迟是否影响客户评分
-- 业务目的：分析配送时效与客户满意度的关联，验证物流投入的必要性
SELECT 
    CASE 
        WHEN DATEDIFF(Delivery_Date, Order_Date) <= 3 THEN '1-3天（快速）'
        WHEN DATEDIFF(Delivery_Date, Order_Date) <= 7 THEN '4-7天（正常）'
        ELSE '>7天（延迟）'
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
-- 链路二：客户分层价值贡献
-- 业务目标：分析不同 Tier 客户的消费贡献与行为差异
-- ============================================

-- 2.1 各 Tier 客户基础画像
-- 业务目的：了解各等级客户的数量和基础消费能力
SELECT 
    Customer_Tier,
    COUNT(*) AS customer_count,
    ROUND(AVG(Total_Orders), 2) AS avg_total_orders,
    ROUND(AVG(Total_Spent), 2) AS avg_total_spent
FROM customers
GROUP BY Customer_Tier
ORDER BY avg_total_spent DESC;


-- 2.2 各 Tier 客户销售贡献（核心查询）
-- 业务目的：量化各等级客户对销售额的贡献，识别核心价值来源
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


-- 2.3 各 Tier 客户复购行为
-- 业务目的：评估各等级客户的活跃度和忠诚度
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


-- 2.4 各 Tier 品类偏好 Top 3
-- 业务目的：识别各等级客户的品类偏好，为差异化推荐提供依据
WITH category_rank AS (
    SELECT 
        c.Customer_Tier,
        p.Category,
        COUNT(s.Order_ID) AS order_count,
        ROUND(SUM(s.Total_Amount), 2) AS revenue,
        RANK() OVER (PARTITION BY c.Customer_Tier ORDER BY SUM(s.Total_Amount) DESC) AS category_rank
    FROM customers c
    JOIN sales s ON c.Customer_ID = s.Customer_ID
    JOIN products p ON s.Product_ID = p.Product_ID
    GROUP BY c.Customer_Tier, p.Category
)
SELECT 
    Customer_Tier,
    Category,
    order_count,
    revenue,
    category_rank
FROM category_rank
WHERE category_rank <= 3
ORDER BY Customer_Tier, category_rank;


-- ============================================
-- 链路三：高价值客户流失风险识别
-- 业务目标：识别 Platinum/Gold 客户的流失风险，建立预警机制
-- 注意：数据集最后订单日期距今约 2.2 年，Recency 结果受数据集时间范围影响
-- ============================================

-- 3.1 各 Tier 最近购买时间分布（Recency 分析）
-- 业务目的：评估各等级客户的活跃度和潜在流失风险
WITH customer_recency AS (
    SELECT 
        c.Customer_ID,
        c.Customer_Tier,
        MAX(s.Order_Date) AS last_order_date,
        COUNT(s.Order_ID) AS total_orders,
        SUM(s.Total_Amount) AS total_spent
    FROM customers c
    JOIN sales s ON c.Customer_ID = s.Customer_ID
    GROUP BY c.Customer_ID, c.Customer_Tier
)
SELECT 
    Customer_Tier,
    ROUND(AVG(DATEDIFF(CURDATE(), last_order_date)), 0) AS avg_recency_days,
    MIN(DATEDIFF(CURDATE(), last_order_date)) AS min_recency_days,
    MAX(DATEDIFF(CURDATE(), last_order_date)) AS max_recency_days,
    AVG(total_orders) AS avg_orders,
    AVG(total_spent) AS avg_spent
FROM customer_recency
GROUP BY Customer_Tier
ORDER BY avg_recency_days;


-- 3.2 流失风险客户名单（Platinum/Gold 超 90 天未购买）
-- 业务目的：输出具体需要运营干预的客户名单
WITH customer_recency AS (
    SELECT 
        c.Customer_ID,
        c.Customer_Name,
        c.Customer_Tier,
        c.Email,
        MAX(s.Order_Date) AS last_order_date,
        COUNT(s.Order_ID) AS total_orders,
        SUM(s.Total_Amount) AS total_spent
    FROM customers c
    JOIN sales s ON c.Customer_ID = s.Customer_ID
    GROUP BY c.Customer_ID, c.Customer_Name, c.Customer_Tier, c.Email
)
SELECT 
    Customer_ID,
    Customer_Name,
    Customer_Tier,
    Email,
    last_order_date,
    DATEDIFF(CURDATE(), last_order_date) AS days_since_last_order,
    total_orders,
    ROUND(total_spent, 2) AS total_spent
FROM customer_recency
WHERE Customer_Tier IN ('Platinum', 'Gold')
  AND DATEDIFF(CURDATE(), last_order_date) > 90
ORDER BY days_since_last_order DESC;


-- 3.3 流失客户 vs 活跃客户行为对比
-- 业务目的：对比流失客户与活跃客户的购买行为差异，寻找流失信号
WITH customer_status AS (
    SELECT 
        c.Customer_ID,
        c.Customer_Tier,
        MAX(s.Order_Date) AS last_order_date,
        COUNT(s.Order_ID) AS order_count,
        AVG(s.Total_Amount) AS avg_order_value,
        CASE 
            WHEN MAX(s.Order_Date) < DATE_SUB(CURDATE(), INTERVAL 90 DAY) THEN '流失风险'
            ELSE '活跃'
        END AS status
    FROM customers c
    JOIN sales s ON c.Customer_ID = s.Customer_ID
    WHERE c.Customer_Tier IN ('Platinum', 'Gold')
    GROUP BY c.Customer_ID, c.Customer_Tier
)
SELECT 
    Customer_Tier,
    status,
    COUNT(*) AS customer_count,
    ROUND(AVG(order_count), 2) AS avg_order_count,
    ROUND(AVG(avg_order_value), 2) AS avg_order_value
FROM customer_status
GROUP BY Customer_Tier, status
ORDER BY Customer_Tier, status DESC;


-- 3.4 流失客户最后的购买品类分布
-- 业务目的：识别流失客户最后购买的品类，寻找潜在的品类问题信号
WITH lost_customers AS (
    SELECT Customer_ID
    FROM (
        SELECT 
            c.Customer_ID,
            MAX(s.Order_Date) AS last_order_date
        FROM customers c
        JOIN sales s ON c.Customer_ID = s.Customer_ID
        WHERE c.Customer_Tier IN ('Platinum', 'Gold')
        GROUP BY c.Customer_ID
        HAVING MAX(s.Order_Date) < DATE_SUB(CURDATE(), INTERVAL 90 DAY)
    ) t
)
SELECT 
    p.Category,
    COUNT(s.Order_ID) AS last_purchase_orders,
    ROUND(SUM(s.Total_Amount), 2) AS last_purchase_revenue
FROM sales s
JOIN products p ON s.Product_ID = p.Product_ID
JOIN lost_customers lc ON s.Customer_ID = lc.Customer_ID
WHERE s.Order_Date >= DATE_SUB(CURDATE(), INTERVAL 180 DAY)
GROUP BY p.Category
ORDER BY last_purchase_orders DESC
LIMIT 5;
