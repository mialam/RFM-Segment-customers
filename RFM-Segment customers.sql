-- #Q1-What is the monthly count of customers purchased products in average?

SELECT
  ROUND(AVG(customer_count), 2) AS average_customers_per_month
FROM (
  SELECT
    EXTRACT(MONTH FROM Order_Date) AS order_month,
    EXTRACT(YEAR FROM Order_Date) AS order_year,
    COUNT(DISTINCT customer_id) AS customer_count
  FROM
    Kogan_data
  GROUP BY
    order_year, order_month
  ORDER BY
    order_year DESC,
    order_month DESC
) AS monthly_data;


-- Q2-What is the best-selling product in each country?

SELECT
  sales.Country,
  sales.Product_Name,
  sales.Total_Quantity
FROM
  (
    SELECT
      Country,
      Product_Name,
      SUM(Quantity) AS Total_Quantity
    FROM
      Kogan_data
    GROUP BY
      Country,
      Product_Name
  ) AS sales
JOIN
  (
    SELECT
      Country,
      MAX(Total_Quantity) AS Max_Quantity
    FROM
      (
        SELECT
          Country,
          Product_Name,
          SUM(Quantity) AS Total_Quantity
        FROM
          Kogan_data
        GROUP BY
          Country,
          Product_Name
      ) AS sales_by_country
    GROUP BY
      Country
  ) AS max_sales
ON
  sales.Country = max_sales.Country
  AND sales.Total_Quantity = max_sales.Max_Quantity
ORDER BY
  sales.Country;


-- Q3-Calculate the RFM (Recency, Frequency, and Monetary) scores for each customer based on their order history
SELECT
  Customer_ID,
  DATEDIFF(CURRENT_DATE(), MAX(Order_Date)) AS recency_value,
  COUNT(Order_Date) AS frequency_value,
  SUM(Sales) AS monetary_value
FROM
  Kogan_data
GROUP BY
  Customer_ID
ORDER BY
  recency_value ASC, 
  frequency_value DESC, 
  monetary_value DESC;


-- Q4-How can customers be categorized into distinct groups based on their engagement and spending behaviors?
WITH rfm AS (
  SELECT
    Customer_ID,
    DATEDIFF(CURRENT_DATE(), MAX(Order_Date)) AS recency_score, 
    COUNT(DISTINCT Order_Date) AS frequency_score,
    SUM(Sales) AS monetary_score
  FROM Kogan_data
  GROUP BY Customer_ID
),
rfm_categories AS (
  SELECT
    Customer_ID,
    recency_score, 
    frequency_score, 
    monetary_score,
    NTILE(5) OVER (ORDER BY recency_score DESC) AS recency_group,
    NTILE(5) OVER (ORDER BY frequency_score ASC) AS frequency_group,
    NTILE(5) OVER (ORDER BY monetary_score ASC) AS monetary_group
  FROM rfm
)
SELECT
  Customer_ID, 
  recency_score, 
  frequency_score, 
  monetary_score,
  CONCAT(recency_group, frequency_group, monetary_group) AS customer_segment
FROM rfm_categories
ORDER BY customer_segment DESC;


-- Q5.How can the total RFM score for each customer be calculated by summing their recency, frequency, and monetary quintiles?
WITH rfm_scores AS (
  SELECT
    Customer_ID,
    DATEDIFF(CURRENT_DATE(), MAX(Order_Date)) AS recency_score,     COUNT(DISTINCT Order_Date) AS frequency_score,
    SUM(Sales) AS monetary_score
  FROM Kogan_data
  GROUP BY Customer_ID
),
rfm_quintiles AS (
  SELECT
    Customer_ID,
    recency_score,
    frequency_score,
    monetary_score,
    NTILE(5) OVER (ORDER BY recency_score DESC) AS recency_quintile,
    NTILE(5) OVER (ORDER BY frequency_score ASC) AS frequency_quintile,
    NTILE(5) OVER (ORDER BY monetary_score ASC) AS monetary_quintile
  FROM rfm_scores
)
SELECT
  Customer_ID,
  recency_score,
  frequency_score,
  monetary_score,
  recency_quintile + frequency_quintile + monetary_quintile AS rfm_score
FROM rfm_quintiles
ORDER BY rfm_score DESC;

-- Q6-How can customers be segmented based on Recency, Frequency, and Monetary (RFM) analysis to identify high-value, at-risk, and new customers for targeted marketing?
WITH rfm_scores AS (
  SELECT
    Customer_ID,
    DATEDIFF(CURRENT_DATE(), MAX(Order_Date)) AS recency_score, 
    COUNT(DISTINCT Order_Date) AS frequency_score,
    SUM(Sales) AS monetary_score
  FROM Kogan_data
  GROUP BY Customer_ID
),
rfm_quintiles AS (
  SELECT
    Customer_ID,
    recency_score,
    frequency_score,
    monetary_score,
    NTILE(5) OVER (ORDER BY recency_score DESC) AS recency_quintile,
    NTILE(5) OVER (ORDER BY frequency_score ASC) AS frequency_quintile,
    NTILE(5) OVER (ORDER BY monetary_score ASC) AS monetary_quintile
  FROM rfm_scores
),
rfm_segments AS (
  SELECT
    Customer_ID,
    recency_score,
    frequency_score,
    monetary_score,
    CONCAT(recency_quintile, frequency_quintile, monetary_quintile) AS rfm_cell,
    CASE
      WHEN CONCAT(recency_quintile, frequency_quintile, monetary_quintile) IN ('555', '554', '545') THEN 'Champions'
      WHEN CONCAT(recency_quintile, frequency_quintile, monetary_quintile) IN ('445', '435', '344') THEN 'Potential Loyal'
      WHEN CONCAT(recency_quintile, frequency_quintile, monetary_quintile) IN ('533', '532', '513', '512') THEN 'Recent Customers'
      WHEN CONCAT(recency_quintile, frequency_quintile, monetary_quintile) IN ('435', '434', '433') THEN 'Loyal Customers'
      WHEN CONCAT(recency_quintile, frequency_quintile, monetary_quintile) IN ('111', '212', '221') THEN 'Churners'
      WHEN CONCAT(recency_quintile, frequency_quintile, monetary_quintile) IN ('543', '542', '541') THEN 'New Customers'
      WHEN CONCAT(recency_quintile, frequency_quintile, monetary_quintile) IN ('321', '322', '323') THEN 'Low-Value Customers'
      ELSE 'Other'
    END AS rfm_segment
  FROM
    rfm_quintiles
)
SELECT
  Customer_ID,
  rfm_segment,
  rfm_cell,
  recency_score,
  frequency_score,
  monetary_score
FROM
  rfm_segments
ORDER BY
  rfm_cell DESC;

