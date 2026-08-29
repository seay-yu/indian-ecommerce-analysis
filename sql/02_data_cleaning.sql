-- ============================================
-- 项目：印度电商数据分析项目
-- 文件：02_data_cleaning.sql
-- 用途：日期字段类型转换 + 零日期处理
-- 数据库：indian_ecommerce_project
-- 作者：[彭显余]
-- 创建时间：2026-08-29
-- 注意事项：
--   1. 执行前请确认数据库名称为 indian_ecommerce_project
--   2. 需在 01_schema.sql 执行成功后运行
--   3. 脚本会临时关闭严格模式，执行完成后自动恢复
-- ============================================

USE indian_ecommerce_project;

-- 步骤1：临时关闭严格模式
-- 目的：允许将 '0000-00-00' 从 VARCHAR 安全转换为 DATE 类型
SET sql_mode = 'NO_ENGINE_SUBSTITUTION';

-- 步骤2：修改字段类型 (VARCHAR → DATE)
-- 注意：不含字段重命名，仅修改数据类型
ALTER TABLE customers MODIFY COLUMN Date_of_Birth DATE COMMENT '出生日期';
ALTER TABLE sales MODIFY COLUMN Order_Date DATE COMMENT '下单日期';
ALTER TABLE sales MODIFY COLUMN Delivery_Date DATE COMMENT '送达日期';

-- 步骤3：数据质量清洗
-- 问题：原始 CSV 中使用 '0000-00-00' 表示未知日期
-- 方案：统一替换为 NULL，避免后续日期计算报错或结果异常
UPDATE customers SET Date_of_Birth = NULL WHERE Date_of_Birth = '0000-00-00';
UPDATE sales SET Order_Date = NULL WHERE Order_Date = '0000-00-00';
UPDATE sales SET Delivery_Date = NULL WHERE Delivery_Date = '0000-00-00';

-- 步骤4：验证清洗结果 (执行后应返回 0)
-- SELECT COUNT(*) FROM customers WHERE Date_of_Birth = '0000-00-00';
-- SELECT COUNT(*) FROM sales WHERE Order_Date = '0000-00-00' OR Delivery_Date = '0000-00-00';

-- 步骤5：恢复严格模式
-- 兼容 MySQL 8.0+，已移除废弃参数 NO_AUTO_CREATE_USER
SET sql_mode = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION,ERROR_FOR_DIVISION_BY_ZERO,NO_ZERO_DATE,NO_ZERO_IN_DATE';
