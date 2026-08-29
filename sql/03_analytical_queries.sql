-- ============================================
-- 项目：印度电商数据分析项目
-- 文件：03_analytical_queries.sql
-- 用途：三条分析链路的核心 SQL 查询
-- 数据库：indian_ecommerce_project
-- 作者：[彭显余]
-- 创建时间：2026-08-29
-- 注意事项：需在 01_schema.sql 和 02_data_cleaning.sql 执行成功后运行
-- ============================================

USE indian_ecommerce_project;

-- ============================================
-- 链路一：物流效率瓶颈定位
-- ============================================

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
