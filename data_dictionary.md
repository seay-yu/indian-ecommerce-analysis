# 数据字典（Data Dictionary）

## customers（客户表）

| 字段名 | 类型 | 允许空 | 说明 |
|--------|------|--------|------|
| Customer_ID | VARCHAR(50) | NO | 客户唯一标识（主键） |
| Customer_Name | VARCHAR(100) | YES | 客户姓名 |
| Gender | VARCHAR(10) | YES | 性别（male/female） |
| Age | INT | YES | 客户年龄 |
| Age_Group | VARCHAR(20) | YES | 年龄段分组（18-25, 26-35等） |
| Date_of_Birth | DATE | YES | 出生日期 |
| Email | VARCHAR(100) | YES | 电子邮箱 |
| Customer_Tier | VARCHAR(20) | YES | 会员等级（Gold/Platinum/Silver） |
| Total_Orders | INT | YES | 历史总订单数 |
| Total_Spent | DECIMAL(10,2) | YES | 历史总消费金额 |

## products（产品表）

| 字段名 | 类型 | 允许空 | 说明 |
|--------|------|--------|------|
| Product_ID | VARCHAR(50) | NO | 产品唯一标识（主键） |
| Product_Name | VARCHAR(200) | YES | 产品名称 |
| Category | VARCHAR(50) | YES | 产品品类 |
| Brand | VARCHAR(50) | YES | 品牌 |
| Original_Price | DECIMAL(10,2) | YES | 原价 |
| Avg_Rating | DECIMAL(3,2) | YES | 平均评分（1-5） |
| Total_Reviews | INT | YES | 总评论数 |

## sales（销售订单表）

| 字段名 | 类型 | 允许空 | 说明 |
|--------|------|--------|------|
| Order_ID | VARCHAR(50) | NO | 订单号（主键） |
| Customer_ID | VARCHAR(50) | YES | 客户ID（外键 → customers） |
| Product_ID | VARCHAR(50) | YES | 产品ID（外键 → products） |
| Order_Date | DATE | YES | 下单日期 |
| Order_Time | TIME | YES | 下单时间 |
| Delivery_Date | DATE | YES | 送达日期 |
| Quantity | INT | YES | 购买数量 |
| Order_Value | DECIMAL(10,2) | YES | 订单金额 |
| Shipping_Cost | DECIMAL(10,2) | YES | 运费 |
| Coupon_Code | VARCHAR(50) | YES | 优惠券代码 |
| Coupon_Discount | DECIMAL(10,2) | YES | 优惠金额 |
| Total_Amount | DECIMAL(10,2) | YES | 实付总金额 |
| Payment_Mode | VARCHAR(30) | YES | 支付方式 |
| Order_Status | VARCHAR(30) | YES | 订单状态 |
| Rating | INT | YES | 评分（1-5） |
| Review_Text | TEXT | YES | 评论内容 |
| City | VARCHAR(50) | YES | 城市 |
| State | VARCHAR(50) | YES | 邦（印度省级行政区） |
| Customer_Age | INT | YES | 下单时客户年龄 |
| Customer_Age_Group | VARCHAR(20) | YES | 下单时客户年龄段 |
