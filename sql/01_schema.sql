-- ============================================
-- 项目：印度电商数据分析项目
-- 文件：01_schema.sql
-- 用途：创建 customers、products、sales 三张表
-- 数据库：indian_ecommerce_project
-- 作者：[彭显余]
-- 创建时间：2026-08-29
-- 注意事项：按 01→02→03 顺序执行
-- ============================================

USE indian_ecommerce_project;

-- 1. 客户表
-- 用途：存储客户个人信息、会员等级、历史消费汇总
CREATE TABLE IF NOT EXISTS customers (
    Customer_ID VARCHAR(50) PRIMARY KEY COMMENT '客户唯一标识',
    Customer_Name VARCHAR(100) COMMENT '客户姓名',
    Gender VARCHAR(10) COMMENT '性别 (male/female)',
    Age INT COMMENT '客户年龄',
    Age_Group VARCHAR(20) COMMENT '年龄段分组',
    Date_of_Birth DATE COMMENT '出生日期',
    Email VARCHAR(100) COMMENT '电子邮箱',
    Customer_Tier VARCHAR(20) COMMENT '会员等级 (Gold/Platinum/Silver)',
    Total_Orders INT COMMENT '历史总订单数',
    Total_Spent DECIMAL(10,2) COMMENT '历史总消费金额'
) COMMENT='客户主数据表';

-- 2. 产品表
-- 用途：存储产品信息、品类、品牌、定价及评分
CREATE TABLE IF NOT EXISTS products (
    Product_ID VARCHAR(50) PRIMARY KEY COMMENT '产品唯一标识',
    Product_Name VARCHAR(200) COMMENT '产品名称',
    Category VARCHAR(50) COMMENT '产品品类',
    Brand VARCHAR(50) COMMENT '品牌',
    Original_Price DECIMAL(10,2) COMMENT '原价',
    Avg_Rating DECIMAL(3,2) COMMENT '平均评分 (1-5)',
    Total_Reviews INT COMMENT '总评论数'
) COMMENT='产品主数据表';

-- 3. 销售订单表
-- 用途：存储每笔交易的订单明细，含支付方式、物流状态及客户评价
CREATE TABLE IF NOT EXISTS sales (
    Order_ID VARCHAR(50) PRIMARY KEY COMMENT '订单号',
    Customer_ID VARCHAR(50) COMMENT '客户ID (外键→customers)',
    Product_ID VARCHAR(50) COMMENT '产品ID (外键→products)',
    Order_Date DATE COMMENT '下单日期',
    Order_Time TIME COMMENT '下单时间',
    Delivery_Date DATE COMMENT '送达日期',
    Quantity INT COMMENT '购买数量',
    Order_Value DECIMAL(10,2) COMMENT '订单金额',
    Shipping_Cost DECIMAL(10,2) COMMENT '运费',
    Coupon_Code VARCHAR(50) COMMENT '优惠券代码',
    Coupon_Discount DECIMAL(10,2) COMMENT '优惠金额',
    Total_Amount DECIMAL(10,2) COMMENT '实付总金额',
    Payment_Mode VARCHAR(30) COMMENT '支付方式',
    Order_Status VARCHAR(30) COMMENT '订单状态',
    Rating INT COMMENT '评分 (1-5)',
    Review_Text TEXT COMMENT '评论内容',
    City VARCHAR(50) COMMENT '城市',
    State VARCHAR(50) COMMENT '邦 (印度省级行政区)',
    Customer_Age INT COMMENT '下单时客户年龄',
    Customer_Age_Group VARCHAR(20) COMMENT '下单时客户年龄段',
    FOREIGN KEY (Customer_ID) REFERENCES customers(Customer_ID),
    FOREIGN KEY (Product_ID) REFERENCES products(Product_ID)
) COMMENT='销售订单明细表';
