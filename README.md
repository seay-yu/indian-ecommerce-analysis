# 🛍️ 印度电商数据分析项目

> 📌 **项目状态**：数据清洗已完成 ✅ | 深度分析进行中 🚧

**项目简介**：基于 Kaggle 公开数据集，对印度电商平台的 25 万条销售记录进行多维度 SQL 分析，涵盖客户分层、产品表现、物流效率三大方向，输出可落地的业务洞察与改善建议。

**数据库**：MySQL 8.0 | 数据库名：`indian_ecommerce`

---

## 📁 数据来源

- **数据集名称**：Indian E-Commerce Sales Analytics Dataset
- **来源平台**：[Kaggle](https://www.kaggle.com/datasets/jatinkhandelwal112/indian-e-commerce-sales-analytics-dataset)
- **数据规模**：25 万条销售记录 | 4 万名客户 | 2,000 款产品
- **表结构**：
  - `customers`：客户主数据（含年龄、会员等级、消费总额）
  - `products`：产品主数据（含品类、品牌、价格、评分）
  - `sales`：销售订单明细（含订单日期、金额、物流状态）

---

## 📊 分析目标

本项目围绕以下三个业务方向展开深度分析：

| 分析方向 | 业务问题 | 预期产出 |
|----------|----------|----------|
| **物流效率分析** | 哪些区域配送时效过长？是否影响客户满意度？ | 各邦/城市物流时效排名 + 改善建议 |
| **客户分层贡献** | 不同 Tier 客户的消费贡献差异有多大？ | 各 Tier 贡献度对比 + 运营策略建议 |
| **流失风险识别** | 高价值客户是否正在流失？ | 流失预警名单 + 召回策略 |

---

## 🛠️ 技术栈

| 工具 | 用途 |
|------|------|
| **MySQL 8.0** | 数据存储与 SQL 分析 |
| **Navicat** | 数据库管理与查询执行 |
| **Excel / Power BI** | 数据可视化与仪表板制作 |
| **Git & GitHub** | 版本控制与项目托管 |

---

## 🔧 数据清洗（已完成）

在进行分析之前，对原始数据执行了以下清洗操作：

1. **日期字段类型转换**：将 `customers.Date_of_Birth`、`sales.Order_Date`、`sales.Delivery_Date` 从 `VARCHAR` 改为 `DATE` 类型，确保日期计算函数的正确性。
2. **零日期处理**：将原始 CSV 中的占位符 `'0000-00-00'` 统一替换为 `NULL`（表示缺失值）。
3. **严格模式兼容**：在转换过程中临时关闭 MySQL 严格模式，清洗完成后恢复（兼容 MySQL 8.0，已移除废弃参数 `NO_AUTO_CREATE_USER`）。

📄 完整清洗脚本：[sql/02_data_cleaning.sql](sql/02_data_cleaning.sql)

---

## 📂 项目结构
indian-ecommerce-analysis/
├── README.md # 项目说明文档
├── data_dictionary.md # 数据字典
├── sql/
│ ├── 01_schema.sql # 建表语句
│ ├── 02_data_cleaning.sql # 数据清洗脚本
│ └── 03_analytical_queries.sql # 核心分析查询
├── exports/ # CSV 导出文件（.gitignore 忽略）
├── excel/ # Excel 透视表
└── powerbi/ # Power BI 仪表板

---

## 📈 分析成果（进行中）

> ⏳ 以下内容将在 SQL 分析完成后补充

### 洞察一：物流效率存在明显区域差异
**状态**：`⏳ 分析中`

**待输出内容**：
- 各邦平均配送时效排名
- 延迟订单占比 Top 10 城市
- 物流时效与客户评分的关联分析
- 解决方案：优化物流商/增设仓储

---

### 洞察二：Platinum 客户是核心价值来源
**状态**：`⏳ 分析中`

**待输出内容**：
- 各 Tier 客户数量占比 vs 销售额贡献占比
- 各 Tier 平均客单价对比
- 各 Tier 复购行为差异
- 解决方案：VIP 专属权益/升级激励

---

### 洞察三：高价值客户流失风险预警
**状态**：`⏳ 分析中`

**待输出内容**：
- 各 Tier 最近购买时间分布
- 流失风险客户名单
- 流失前的购买信号识别
- 解决方案：流失预警机制/召回策略

---

## 🚀 下一步计划

- [ ] 运行三条链路的 SQL 分析查询
- [ ] 将关键结果导出为 CSV
- [ ] 制作 Excel 透视图表
- [ ] 导入 Power BI 制作仪表板
- [ ] 补充 README 分析成果摘要
- [ ] 将仓库设为 Public 并更新简历

---

**项目创建时间**：2026-08-29  
**作者**：[彭显余]  
**GitHub**：[github.com/seay-yu/indian-ecommerce-analysis](https://github.com/seay-yu/indian-ecommerce-analysis)
