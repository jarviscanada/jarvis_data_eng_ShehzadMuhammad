-- Show table schema
\d+ retail;

-- Show first 10 rows
SELECT * FROM retail limit 10;

-- Check # of records
SELECT COUNT(*) FROM retail;

-- number of clients (e.g. unique client ID)
SELECT COUNT(DISTINCT customer_id) from retail;

--invoice date range (e.g. max/min dates)
SELECT MAX(invoice_date) AS "max", MIN(invoice_date) as "min" from retail;

--number of SKU/merchants (e.g. unique stock code)
SELECT COUNT(DISTINCT stock_code) from retail;

--Calculate average invoice amount excluding invoices with a negative amount (e.g. canceled orders have negative amount)
SELECT AVG(invoice_total) as "avg"
FROM (
	SELECT
			invoice_no,
			SUM(unit_price * quantity) AS invoice_total
	FROM retail
	GROUP BY invoice_no
	HAVING SUM(unit_price * quantity) > 0
) invoices

--Calculate total revenue (e.g. sum of unit_price * quantity)
SELECT SUM(unit_price * quantity) as "total revenue"
FROM retail

--Calculate total revenue by YYYYMM
SELECT
  to_char(invoice_date, 'YYYYMM') AS yyyymm,
  SUM(unit_price * quantity) AS total_revenue
FROM retail
GROUP BY to_char(invoice_date, 'YYYYMM')
ORDER BY yyyymm;
