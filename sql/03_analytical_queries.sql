-- ================================================================
-- 项目：印度电商数据分析项目
-- 文件：03_analytical_queries.sql
-- 用途：四大板块核心分析 SQL 查询
--       板块一：交易表现分析
--       板块二：客户结构分析
--       板块三：履约效率分析
--       板块四：售后质量分析
-- 数据库：indian_ecommerce_project
-- 作者：彭显余 (GitHub: seay-yu)
-- 创建时间：2026-08-29
-- 更新时间：2026-08-31
-- ================================================================


USE indian_ecommerce_project;


-- ================================================================
-- 板块一：交易表现分析
-- 核心问题：Q2 业务变化来自订单量还是客单价？
-- CEO 问题："Q2 业务变化主要来自哪里？是订单量变化，还是客单价在变化？"
-- 分析维度：同比（Q2 2026 vs Q2 2025）+ 环比（Q2 2026 vs Q1 2026）
-- ================================================================


-- 1.1 季度核心指标总览（同比 + 环比）
-- 用途：一次输出 2025Q2、2026Q1、2026Q2 三个季度的核心指标，便于同比和环比对比
WITH quarterly_metrics AS (
    SELECT 
        CASE 
            WHEN Order_Date BETWEEN '2025-04-01' AND '2025-06-30' THEN '2025Q2'
            WHEN Order_Date BETWEEN '2026-01-01' AND '2026-03-31' THEN '2026Q1'
            WHEN Order_Date BETWEEN '2026-04-01' AND '2026-06-30' THEN '2026Q2'
        END AS quarter,
        COUNT(DISTINCT Order_ID) AS order_count,
        ROUND(SUM(Total_Amount), 2) AS total_revenue,
        ROUND(COUNT(DISTINCT Customer_ID), 0) AS active_customers
    FROM sales
    WHERE Order_Date BETWEEN '2025-04-01' AND '2026-06-30'
      AND Order_Date IS NOT NULL
    GROUP BY quarter
)
SELECT 
    quarter,
    order_count,
    total_revenue,
    active_customers,
    ROUND(total_revenue / order_count, 2) AS avg_order_value
FROM quarterly_metrics
WHERE quarter IS NOT NULL
ORDER BY quarter;


-- 1.2 Q2 各月明细（2026年4月、5月、6月）
-- 用途：查看 Q2 内部三个月的月度变化，识别是否有异常月份
SELECT 
    DATE_FORMAT(Order_Date, '%Y-%m') AS month,
    COUNT(DISTINCT Order_ID) AS order_count,
    ROUND(SUM(Total_Amount), 2) AS revenue,
    ROUND(AVG(Total_Amount), 2) AS avg_order_value
FROM sales
WHERE Order_Date BETWEEN '2026-04-01' AND '2026-06-30'
  AND Order_Date IS NOT NULL
GROUP BY month
ORDER BY month;


-- 1.3 Q2 各邦同比变化（定位问题区域）
-- 用途：识别哪些邦的订单量和销售额同比下滑最严重，定位问题区域
WITH q2_2025 AS (
    SELECT 
        State,
        COUNT(DISTINCT Order_ID) AS order_count_2025,
        ROUND(SUM(Total_Amount), 2) AS revenue_2025
    FROM sales
    WHERE Order_Date BETWEEN '2025-04-01' AND '2025-06-30'
      AND State IS NOT NULL
    GROUP BY State
),
q2_2026 AS (
    SELECT 
        State,
        COUNT(DISTINCT Order_ID) AS order_count_2026,
        ROUND(SUM(Total_Amount), 2) AS revenue_2026
    FROM sales
    WHERE Order_Date BETWEEN '2026-04-01' AND '2026-06-30'
      AND State IS NOT NULL
    GROUP BY State
)
-- 全连接：保留 2025 和 2026 所有邦
SELECT 
    COALESCE(a.State, b.State) AS State,
    COALESCE(a.order_count_2025, 0) AS order_count_2025,
    COALESCE(b.order_count_2026, 0) AS order_count_2026,
    ROUND(
        (COALESCE(b.order_count_2026, 0) - COALESCE(a.order_count_2025, 0)) / NULLIF(a.order_count_2025, 0) * 100, 
        2
    ) AS order_change_pct,
    COALESCE(a.revenue_2025, 0) AS revenue_2025,
    COALESCE(b.revenue_2026, 0) AS revenue_2026,
    ROUND(
        (COALESCE(b.revenue_2026, 0) - COALESCE(a.revenue_2025, 0)) / NULLIF(a.revenue_2025, 0) * 100, 
        2
    ) AS revenue_change_pct
FROM q2_2025 a
LEFT JOIN q2_2026 b ON a.State = b.State

UNION

SELECT 
    COALESCE(a.State, b.State) AS State,
    COALESCE(a.order_count_2025, 0) AS order_count_2025,
    COALESCE(b.order_count_2026, 0) AS order_count_2026,
    ROUND(
        (COALESCE(b.order_count_2026, 0) - COALESCE(a.order_count_2025, 0)) / NULLIF(a.order_count_2025, 0) * 100, 
        2
    ) AS order_change_pct,
    COALESCE(a.revenue_2025, 0) AS revenue_2025,
    COALESCE(b.revenue_2026, 0) AS revenue_2026,
    ROUND(
        (COALESCE(b.revenue_2026, 0) - COALESCE(a.revenue_2025, 0)) / NULLIF(a.revenue_2025, 0) * 100, 
        2
    ) AS revenue_change_pct
FROM q2_2025 a
RIGHT JOIN q2_2026 b ON a.State = b.State

WHERE COALESCE(a.State, b.State) IS NOT NULL
ORDER BY order_change_pct ASC;


-- ================================================================
-- 补充分析：Karnataka 品类结构分析
-- 用途：深挖 Karnataka 逆势增长的原因，对比其与全平台的品类结构差异
-- ================================================================

-- A1. Karnataka vs 全平台：各品类销售额占比对比
WITH category_sales AS (
    SELECT 
        CASE 
            WHEN State = 'Karnataka' THEN 'Karnataka'
            ELSE '其他邦'
        END AS region,
        p.Category,
        ROUND(SUM(s.Total_Amount), 2) AS revenue,
        ROUND(SUM(s.Total_Amount) / SUM(SUM(s.Total_Amount)) OVER (PARTITION BY CASE WHEN State = 'Karnataka' THEN 'Karnataka' ELSE '其他邦' END) * 100, 2) AS pct
    FROM sales s
    JOIN products p ON s.Product_ID = p.Product_ID
    WHERE s.Order_Date BETWEEN '2026-04-01' AND '2026-06-30'
      AND s.State IS NOT NULL
    GROUP BY region, p.Category
)
SELECT 
    Category,
    MAX(CASE WHEN region = 'Karnataka' THEN pct END) AS Karnataka_占比,
    MAX(CASE WHEN region = '其他邦' THEN pct END) AS 其他邦_占比,
    ROUND(
        MAX(CASE WHEN region = 'Karnataka' THEN pct END) - 
        MAX(CASE WHEN region = '其他邦' THEN pct END), 2
    ) AS 占比差异
FROM category_sales
GROUP BY Category
ORDER BY 占比差异 DESC;


-- ================================================================
-- 板块二：客户结构分析
-- 核心问题：Platinum 客户是否值得维护？
-- CEO 问题："我们花那么多钱维护 Platinum 客户，真的值得吗？"
-- 分析维度：贡献占比 + 人均消费倍数 + 流失损失测算 + Q2动态验证 + RFM交叉验证
-- ================================================================


-- 2.1 各等级客户销售贡献（核心查询）
-- 用途：回答 CEO 核心问题 — Platinum 贡献了多少销售额？
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


-- 2.2 各等级客户人均消费对比（Platinum 是其他等级的多少倍）
-- 用途：计算 Platinum 人均消费是 Gold/Silver 的多少倍，量化价值差距
WITH tier_avg AS (
    SELECT 
        Customer_Tier,
        ROUND(AVG(Total_Spent), 2) AS avg_spent
    FROM customers
    GROUP BY Customer_Tier
)
SELECT 
    Customer_Tier,
    avg_spent,
    ROUND(avg_spent / (SELECT avg_spent FROM tier_avg WHERE Customer_Tier = 'Silver'), 2) AS times_of_silver,
    ROUND(avg_spent / (SELECT avg_spent FROM tier_avg WHERE Customer_Tier = 'Gold'), 2) AS times_of_gold
FROM tier_avg
ORDER BY avg_spent DESC;


-- 2.3 各等级客户活跃率与复购表现（验证粘性）
-- 用途：验证 Platinum 客户是否活跃、是否忠诚（活跃率 + 人均订单数）
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


-- ================================================================
-- 补充分析一：Q2 动态等级划分验证
-- 用途：验证全量结论在 Q2 单季度是否同样成立
-- 方法：基于 Q2 消费金额分位数动态划分等级（前20%为Platinum）
-- 注意：PERCENT_RANK 并列值会导致实际分层占比偏离 20%/30%/50%
-- ================================================================

WITH 
q2_total AS (
    SELECT SUM(Total_Amount) AS total_revenue
    FROM sales
    WHERE Order_Date BETWEEN '2026-04-01' AND '2026-06-30'
),
q2_spend AS (
    SELECT 
        c.Customer_ID,
        SUM(s.Total_Amount) AS q2_spend
    FROM customers c
    JOIN sales s ON c.Customer_ID = s.Customer_ID
    WHERE s.Order_Date BETWEEN '2026-04-01' AND '2026-06-30'
    GROUP BY c.Customer_ID
),
q2_rank AS (
    SELECT 
        Customer_ID,
        q2_spend,
        PERCENT_RANK() OVER (ORDER BY q2_spend) AS pct_rank
    FROM q2_spend
),
q2_tier AS (
    SELECT 
        Customer_ID,
        CASE 
            WHEN pct_rank >= 0.8 THEN 'Platinum'
            WHEN pct_rank >= 0.5 THEN 'Gold'
            ELSE 'Silver'
        END AS q2_tier
    FROM q2_rank
)
SELECT 
    qt.q2_tier,
    COUNT(DISTINCT qt.Customer_ID) AS customer_count,
    ROUND(
        COUNT(DISTINCT qt.Customer_ID) / (SELECT COUNT(DISTINCT Customer_ID) FROM q2_spend) * 100, 
        2
    ) AS customer_pct,
    ROUND(SUM(qs.q2_spend), 2) AS total_revenue,
    ROUND(
        SUM(qs.q2_spend) / (SELECT total_revenue FROM q2_total) * 100, 
        2
    ) AS revenue_share_pct,
    ROUND(AVG(qs.q2_spend), 2) AS avg_spend_per_customer
FROM q2_tier qt
JOIN q2_spend qs ON qt.Customer_ID = qs.Customer_ID
GROUP BY qt.q2_tier
ORDER BY total_revenue DESC;


-- ================================================================
-- 补充分析二：RFM 模型交叉验证
-- 用途：从 R（最近购买）、F（购买频次）、M（消费金额）三维度交叉验证
-- 版本：全量历史数据版，截止日期固定为 2026-06-30
-- 评分阈值基于实际数据分布微调
-- ================================================================

WITH 
rfm_raw AS (
    SELECT 
        c.Customer_ID,
        DATEDIFF('2026-06-30', MAX(s.Order_Date)) AS recency,
        COUNT(DISTINCT s.Order_ID) AS frequency,
        ROUND(SUM(s.Total_Amount), 2) AS monetary
    FROM customers c
    LEFT JOIN sales s ON c.Customer_ID = s.Customer_ID
    GROUP BY c.Customer_ID
),
rfm_score AS (
    SELECT 
        Customer_ID,
        recency,
        frequency,
        monetary,
        -- Recency 评分：距今越近分数越高
        -- 分布依据：61-120天客户数最多（15,294人），需与 >180天区分
        CASE 
            WHEN recency <= 30 THEN 5
            WHEN recency <= 60 THEN 4
            WHEN recency <= 120 THEN 3
            WHEN recency <= 180 THEN 2
            ELSE 1
        END AS recency_score,
        -- Frequency 评分：购买次数越多分数越高
        -- 分布依据：7-9单（13,303人）、5-6单（12,502人）为主
        -- 10单以上单独设6分，突出高频客户
        CASE 
            WHEN frequency >= 10 THEN 6
            WHEN frequency >= 7 THEN 5
            WHEN frequency >= 5 THEN 4
            WHEN frequency >= 3 THEN 3
            ELSE 1
        END AS frequency_score,
        -- Monetary 评分：消费金额越高分数越高
        -- 分布依据：>10万客户占绝对多数（22,727人）
        CASE 
            WHEN monetary >= 100000 THEN 5
            WHEN monetary >= 50000 THEN 4
            WHEN monetary >= 20000 THEN 3
            WHEN monetary >= 10000 THEN 2
            ELSE 1
        END AS monetary_score
    FROM rfm_raw
),
rfm_final AS (
    SELECT 
        *,
        (recency_score + frequency_score + monetary_score) AS rfm_score,
        CASE 
            -- 核心用户：R高 + F高 + M高
            WHEN recency_score >= 4 AND frequency_score >= 5 AND monetary_score >= 4 THEN '核心用户'
            -- 高价值沉睡用户：累计消费高但近期不活跃（需召回）
            WHEN recency_score <= 2 AND frequency_score >= 4 AND monetary_score >= 4 THEN '高价值沉睡用户'
            -- 活跃用户：近期活跃，有升级潜力
            WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 THEN '活跃用户'
            -- 流失风险：长期不活跃 + 消费低
            WHEN recency_score <= 2 AND frequency_score >= 1 AND monetary_score >= 1 THEN '流失风险'
            ELSE '一般用户'
        END AS user_segment
    FROM rfm_score
)
SELECT 
    user_segment,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM rfm_final) * 100, 2) AS customer_pct,
    ROUND(AVG(rfm_score), 2) AS avg_rfm_score,
    ROUND(AVG(monetary), 2) AS avg_monetary
FROM rfm_final
GROUP BY user_segment
ORDER BY avg_monetary DESC;


-- ================================================================
-- RFM 分布查询（用于辅助阈值设定）
-- 以下三个查询分别查看 Recency / Frequency / Monetary 的分布
-- ================================================================

-- R 分布
SELECT 
    r_range,
    COUNT(*) AS customer_count
FROM (
    SELECT 
        c.Customer_ID,
        CASE 
            WHEN DATEDIFF(CURDATE(), MAX(s.Order_Date)) <= 30 THEN '1-30天'
            WHEN DATEDIFF(CURDATE(), MAX(s.Order_Date)) <= 60 THEN '31-60天'
            WHEN DATEDIFF(CURDATE(), MAX(s.Order_Date)) <= 120 THEN '61-120天'
            WHEN DATEDIFF(CURDATE(), MAX(s.Order_Date)) <= 180 THEN '121-180天'
            ELSE '>180天'
        END AS r_range
    FROM customers c
    LEFT JOIN sales s ON c.Customer_ID = s.Customer_ID
    GROUP BY c.Customer_ID
) t
GROUP BY r_range
ORDER BY MIN(r_range);

-- F 分布
SELECT 
    f_range,
    COUNT(*) AS customer_count
FROM (
    SELECT 
        Customer_ID,
        CASE 
            WHEN COUNT(DISTINCT Order_ID) >= 10 THEN '10单以上'
            WHEN COUNT(DISTINCT Order_ID) >= 7 THEN '7-9单'
            WHEN COUNT(DISTINCT Order_ID) >= 5 THEN '5-6单'
            WHEN COUNT(DISTINCT Order_ID) >= 3 THEN '3-4单'
            ELSE '1-2单'
        END AS f_range
    FROM sales
    GROUP BY Customer_ID
) t
GROUP BY f_range
ORDER BY MIN(f_range) DESC;

-- M 分布
SELECT 
    m_range,
    COUNT(*) AS customer_count
FROM (
    SELECT 
        Customer_ID,
        CASE 
            WHEN SUM(Total_Amount) >= 100000 THEN '10万以上'
            WHEN SUM(Total_Amount) >= 50000 THEN '5万-10万'
            WHEN SUM(Total_Amount) >= 20000 THEN '2万-5万'
            WHEN SUM(Total_Amount) >= 10000 THEN '1万-2万'
            ELSE '1万以下'
        END AS m_range
    FROM sales
    GROUP BY Customer_ID
) t
GROUP BY m_range
ORDER BY MIN(m_range) DESC;


-- ================================================================
-- 板块三：履约效率分析
-- 核心问题：Q2 更换物流商是否带来时效改善？
-- CEO 问题："Q2 更换了 3 个邦的物流商，时效真的改善了吗？"
-- 分析方法：差值分析（Diff-in-Diff）实验组 vs 对照组
-- ================================================================

-- 3.1 差值分析：实验组 vs 对照组
-- 实验组（更换物流商）：Gujarat、Haryana、UP
-- 对照组（未更换）：Tamil Nadu、Punjab、Delhi
-- 时间段：4-5月（旧物流商）vs 6月（新物流商）
WITH logistics_data AS (
    SELECT 
        State,
        Order_Date,
        Delivery_Date,
        DATEDIFF(Delivery_Date, Order_Date) AS delivery_days,
        CASE 
            WHEN State IN ('Gujarat', 'Haryana', 'UP') THEN '实验组（更换物流商）'
            WHEN State IN ('Tamil Nadu', 'Punjab', 'Delhi') THEN '对照组（未更换）'
        END AS group_type,
        CASE 
            WHEN Order_Date BETWEEN '2026-04-01' AND '2026-05-31' THEN '4-5月（旧物流商）'
            WHEN Order_Date BETWEEN '2026-06-01' AND '2026-06-30' THEN '6月（新物流商）'
        END AS period
    FROM sales
    WHERE Order_Date BETWEEN '2026-04-01' AND '2026-06-30'
      AND Delivery_Date IS NOT NULL
      AND State IN ('Gujarat', 'Haryana', 'UP', 'Tamil Nadu', 'Punjab', 'Delhi')
)
SELECT 
    group_type,
    period,
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days,
    COUNT(*) AS order_count
FROM logistics_data
WHERE period IS NOT NULL
GROUP BY group_type, period
ORDER BY group_type, period;

-- 3.2 各邦物流时效排名（全量数据）
-- 用途：作为平台整体物流基线参考
SELECT 
    State,
    ROUND(AVG(DATEDIFF(Delivery_Date, Order_Date)), 2) AS avg_delivery_days,
    COUNT(*) AS order_count
FROM sales
WHERE Order_Date IS NOT NULL 
  AND Delivery_Date IS NOT NULL
  AND State IS NOT NULL
GROUP BY State
ORDER BY avg_delivery_days DESC;


-- ================================================================
-- 板块四：售后质量分析
-- 核心问题：客户满意度是否因订单量变化而受到影响？
-- CEO 问题："客户满意度有没有因为订单量变化而受到影响？"
-- ================================================================

-- 4.1 评分整体分布
-- 用途：查看整体评分结构，识别低评分订单占比
SELECT 
    Rating,
    COUNT(*) AS count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM sales WHERE Rating IS NOT NULL) * 100, 2) AS pct
FROM sales
WHERE Rating IS NOT NULL
GROUP BY Rating
ORDER BY Rating DESC;

-- 4.2 Q2 评分同比变化
-- 用途：直接回答 CEO 问题 — Q2 评分是否同比下滑？
WITH q2_rating AS (
    SELECT 
        CASE 
            WHEN Order_Date BETWEEN '2025-04-01' AND '2025-06-30' THEN '2025Q2'
            WHEN Order_Date BETWEEN '2026-04-01' AND '2026-06-30' THEN '2026Q2'
        END AS quarter,
        Rating
    FROM sales
    WHERE Order_Date BETWEEN '2025-04-01' AND '2026-06-30'
      AND Rating IS NOT NULL
)
SELECT 
    quarter,
    ROUND(AVG(Rating), 2) AS avg_rating,
    COUNT(*) AS review_count
FROM q2_rating
WHERE quarter IS NOT NULL
GROUP BY quarter
ORDER BY quarter;

-- 4.3 月度评分趋势（全量基线）
-- 用途：展示 2024-06 至 2026-06 的评分趋势，验证长期稳定性
SELECT 
    DATE_FORMAT(Order_Date, '%Y-%m') AS month,
    ROUND(AVG(Rating), 2) AS avg_rating,
    COUNT(*) AS review_count
FROM sales
WHERE Rating IS NOT NULL AND Order_Date IS NOT NULL
GROUP BY month
ORDER BY month;

-- 4.4 评分与客单价、运费关联
-- 用途：分析低评分是否与价格或运费有关
SELECT 
    CASE 
        WHEN s.Rating <= 2 THEN '低评分（1-2分）'
        WHEN s.Rating <= 3 THEN '中评分（3分）'
        ELSE '高评分（4-5分）'
    END AS rating_group,
    COUNT(*) AS order_count,
    ROUND(AVG(s.Total_Amount), 2) AS avg_order_value,
    ROUND(AVG(s.Shipping_Cost), 2) AS avg_shipping_cost
FROM sales s
WHERE s.Rating IS NOT NULL
GROUP BY rating_group
ORDER BY MIN(s.Rating);

-- 4.5 各品类平均评分
-- 用途：检查是否有特定品类评分显著低于其他品类
SELECT 
    p.Category,
    ROUND(AVG(s.Rating), 2) AS avg_rating,
    COUNT(*) AS review_count
FROM sales s
JOIN products p ON s.Product_ID = p.Product_ID
WHERE s.Rating IS NOT NULL
GROUP BY p.Category
ORDER BY avg_rating DESC;
