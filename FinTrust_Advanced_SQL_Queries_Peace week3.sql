-- ====================================================================
-- FINTRUST DIGITAL BANK - WEEK 3 ADVANCED SQL ANALYSIS
-- Author: Peace Ofure Vincent
-- Track: Data Analytics
-- ====================================================================

USE FinTrust_Bank;
GO

-- --------------------------------------------------------------------
-- QUERY 1: Customer Transaction Behaviour & Spending by Segment
-- --------------------------------------------------------------------
WITH SegmentSummary AS (
    SELECT 
        c.Customer_Segment,
        COUNT(DISTINCT c.Customer_ID) AS Total_Customers,
        COUNT(t.Transaction_ID) AS Total_Transactions,
        SUM(t.Amount_NGN) AS Total_Spent,
        AVG(t.Amount_NGN) AS Avg_Transaction_Value
    FROM [FINTRUST TRANSACTION DATA] c
    JOIN [FINTRUST CUSTOMER DATA] t ON c.Customer_ID = t.Customer_ID
    GROUP BY c.Customer_Segment
)
SELECT 
    Customer_Segment,
    Total_Customers,
    Total_Transactions,
    ROUND(Total_Spent, 2) AS Total_Volume_NGN,
    ROUND(Avg_Transaction_Value, 2) AS Avg_Txn_Value_NGN,
    ROUND(Total_Spent / Total_Customers, 2) AS Value_Per_Customer
FROM SegmentSummary
ORDER BY Total_Volume_NGN DESC;


-- --------------------------------------------------------------------
-- QUERY 2: Channel Performance - Success vs. Failure Rates
-- --------------------------------------------------------------------
SELECT 
    Channel,
    COUNT(Transaction_ID) AS Total_Transactions,
    SUM(CASE WHEN Transaction_Status = 'Successful' THEN 1 ELSE 0 END) AS Successful_Txns,
    SUM(CASE WHEN Transaction_Status = 'Failed' THEN 1 ELSE 0 END) AS Failed_Txns,
    ROUND(CAST(SUM(CASE WHEN Transaction_Status = 'Failed' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(Transaction_ID) * 100, 2) AS Failure_Rate_Pct,
    ROUND(SUM(CASE WHEN Transaction_Status = 'Failed' THEN Amount_NGN ELSE 0 END), 2) AS Failed_Volume_NGN
FROM [FINTRUST CUSTOMER DATA]
GROUP BY Channel
ORDER BY Failure_Rate_Pct DESC;


-- --------------------------------------------------------------------
-- QUERY 3: International vs. Domestic Risk-Review Patterns
-- --------------------------------------------------------------------
SELECT 
    CASE WHEN International_Transaction = 1 THEN 'International' ELSE 'Domestic' END AS Txn_Location_Type,
    COUNT(Transaction_ID) AS Total_Transactions,
    SUM(CASE WHEN Risk_Review_Flag = 1 THEN 1 ELSE 0 END) AS Flagged_Risk_Txns,
    ROUND(CAST(SUM(CASE WHEN Risk_Review_Flag = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(Transaction_ID) * 100, 2) AS Risk_Flag_Rate_Pct,
    ROUND(SUM(Amount_NGN), 2) AS Total_Amount_NGN
FROM [FINTRUST CUSTOMER DATA]
GROUP BY International_Transaction
ORDER BY Risk_Flag_Rate_Pct DESC;


-- --------------------------------------------------------------------
-- QUERY 4: High-Value Customer Ranking using Window Functions
-- --------------------------------------------------------------------
WITH CustomerVolumes AS (
    SELECT 
        c.Customer_ID,
        c.Customer_Segment,
        c.City,
        COUNT(t.Transaction_ID) AS Txn_Count,
        SUM(t.Amount_NGN) AS Total_Spent
    FROM [FINTRUST TRANSACTION DATA] c
    JOIN [FINTRUST CUSTOMER DATA] t ON c.Customer_ID = t.Customer_ID
    GROUP BY c.Customer_ID, c.Customer_Segment, c.City
)
SELECT 
    Customer_ID,
    Customer_Segment,
    City,
    Txn_Count,
    ROUND(Total_Spent, 2) AS Total_Spent_NGN,
    DENSE_RANK() OVER (PARTITION BY Customer_Segment ORDER BY Total_Spent DESC) AS Segment_Rank
FROM CustomerVolumes
ORDER BY Customer_Segment, Segment_Rank;


-- --------------------------------------------------------------------
-- QUERY 5: Monthly Revenue & Growth Trend
-- --------------------------------------------------------------------
WITH MonthlyMetrics AS (
    SELECT 
        FORMAT(Transaction_DateTime, 'yyyy-MM') AS Txn_Month,
        COUNT(Transaction_ID) AS Total_Transactions,
        SUM(Amount_NGN) AS Total_Monthly_Volume
    FROM [FINTRUST CUSTOMER DATA]
    GROUP BY FORMAT(Transaction_DateTime, 'yyyy-MM')
)
SELECT 
    Txn_Month,
    Total_Transactions,
    ROUND(Total_Monthly_Volume, 2) AS Total_Volume_NGN,
    ROUND(LAG(Total_Monthly_Volume, 1) OVER (ORDER BY Txn_Month), 2) AS Previous_Month_Volume,
    ROUND(Total_Monthly_Volume - LAG(Total_Monthly_Volume, 1) OVER (ORDER BY Txn_Month), 2) AS MoM_Change_NGN
FROM MonthlyMetrics
ORDER BY Txn_Month;


-- --------------------------------------------------------------------
-- QUERY 6: Customer Transaction Frequency & Recency
-- --------------------------------------------------------------------
WITH CustomerActivity AS (
    SELECT 
        c.Customer_ID,
        c.Customer_Segment,
        COUNT(t.Transaction_ID) AS Txn_Count,
        MAX(t.Transaction_DateTime) AS Last_Txn_Date
    FROM [FINTRUST TRANSACTION DATA] c
    LEFT JOIN [FINTRUST CUSTOMER DATA] t ON c.Customer_ID = t.Customer_ID
    GROUP BY c.Customer_ID, c.Customer_Segment
)
SELECT 
    Customer_ID,
    Customer_Segment,
    Txn_Count,
    Last_Txn_Date,
    CASE 
        WHEN Txn_Count >= 20 THEN 'High Frequency'
        WHEN Txn_Count BETWEEN 10 AND 19 THEN 'Medium Frequency'
        ELSE 'Low Frequency'
    END AS Activity_Class
FROM CustomerActivity
ORDER BY Txn_Count DESC;


-- --------------------------------------------------------------------
-- QUERY 7: High-Value Transaction Anomaly Detection
-- --------------------------------------------------------------------
SELECT 
    t.Transaction_ID,
    t.Customer_ID,
    t.Channel,
    t.Amount_NGN,
    t.Transaction_Type,
    t.Risk_Review_Flag
FROM [FINTRUST CUSTOMER DATA] t
WHERE t.Amount_NGN > (SELECT AVG(Amount_NGN) * 3 FROM [FINTRUST CUSTOMER DATA])
ORDER BY t.Amount_NGN DESC;


-- --------------------------------------------------------------------
-- QUERY 8: Overall Risk Exposure by Account Type & Segment
-- --------------------------------------------------------------------
SELECT 
    c.Customer_Segment,
    c.Account_Type,
    COUNT(DISTINCT c.Customer_ID) AS Customer_Count,
    COUNT(t.Transaction_ID) AS Total_Txns,
    SUM(CASE WHEN t.Risk_Review_Flag = 1 THEN 1 ELSE 0 END) AS Flagged_Txns,
    ROUND(SUM(CASE WHEN t.Risk_Review_Flag = 1 THEN t.Amount_NGN ELSE 0 END), 2) AS Exposure_Amount_NGN
FROM [FINTRUST TRANSACTION DATA] c
JOIN [FINTRUST CUSTOMER DATA] t ON c.Customer_ID = t.Customer_ID
GROUP BY c.Customer_Segment, c.Account_Type
ORDER BY Exposure_Amount_NGN DESC;