/*
风控核心指标计算脚本
包含：逾期率、通过率、M1→M2滚动率
适用数据库：SQLite/MySQL
创建时间：2026-02-25
*/

-- ====================== 1. 逾期率计算 ======================
-- 创建贷款表
CREATE TABLE IF NOT EXISTS loan_table (
    user_id INT,               -- 用户ID
    balance DECIMAL(10,2),     -- 贷款余额
    overdue_days INT           -- 逾期天数
);

-- 插入模拟数据
INSERT INTO loan_table VALUES
(1, 10000.00, 0),   -- 未逾期
(2, 20000.00, 15),  -- 逾期15天
(3, 15000.00, 30),  -- 逾期30天
(4, 5000.00, 0),    -- 未逾期
(5, 8000.00, 45);   -- 逾期45天

-- 计算逾期率
SELECT
    SUM(CASE WHEN overdue_days > 0 THEN balance ELSE 0 END) AS total_overdue_balance,
    SUM(balance) AS total_balance,
    ROUND(
        SUM(CASE WHEN overdue_days > 0 THEN balance ELSE 0 END) 
        / NULLIF(SUM(balance), 0) * 100,
        2
    ) AS overdue_rate_percent
FROM loan_table;

-- ====================== 2. 通过率计算 ======================
-- 创建申请表
CREATE TABLE IF NOT EXISTS apply_table (
    apply_id INT,              -- 申请ID
    user_id INT,               -- 用户ID
    apply_date DATE,           -- 申请日期
    status VARCHAR(20)         -- 审批状态：approved/rejected
);

-- 插入模拟数据
INSERT INTO apply_table VALUES
(1, 1, '2025-01-01', 'approved'),
(2, 2, '2025-01-01', 'rejected'),
(3, 3, '2025-01-01', 'approved'),
(4, 4, '2025-01-01', 'approved'),
(5, 5, '2025-01-01', 'rejected');

-- 计算通过率
SELECT
    COUNT(*) AS total_applications,
    SUM(CASE WHEN status = 'approved' THEN 1 ELSE 0 END) AS approved_applications,
    ROUND(
        SUM(CASE WHEN status = 'approved' THEN 1 ELSE 0 END) 
        / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS approval_rate_percent
FROM apply_table;

-- ====================== 3. M1→M2滚动率计算 ======================
-- 创建逾期状态表
CREATE TABLE IF NOT EXISTS migration_table (
    user_id INT,               -- 用户ID
    report_date DATE,          -- 报表日期
    m1_balance DECIMAL(10,2),  -- M1逾期余额（1-30天）
    m2_balance DECIMAL(10,2)   -- M2逾期余额（31-60天）
);

-- 插入模拟数据
INSERT INTO migration_table VALUES
(1, '2025-01-01', 10000.00, 4000.00),
(2, '2025-01-01', 20000.00, 8000.00),
(3, '2025-01-01', 15000.00, 6000.00);

-- 计算M1→M2滚动率（修复SQLite整数除法问题）
SELECT
    SUM(m1_balance) AS previous_m1_balance,
    SUM(m2_balance) AS current_m2_balance,
    ROUND(
        CAST(SUM(m2_balance) AS FLOAT) 
        / NULLIF(SUM(m1_balance), 0) * 100,
        2
    ) AS m1_to_m2_roll_rate_percent
FROM migration_table;