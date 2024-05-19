WITH gnucash_date AS(
SELECT
	date_trunc('month', post_date) AS gnucash_date
FROM 
	transactions
ORDER BY
	post_date ASC
LIMIT 1
),

dates AS (
SELECT
	generate_series(gnucash_date, current_date, '1 Month') :: DATE AS start_date,
	generate_series(gnucash_date + INTERVAL '1 Month', current_date + INTERVAL '1 Month', '1 Month') :: DATE AS end_date
FROM
	gnucash_date
),

income_statement_monthly AS(
SELECT
	a.guid AS account_guid,
	SUM(CASE WHEN t.post_date < d.end_date AND t.post_date >= start_date THEN (s.value_num * 1.0) / s.value_denom ELSE 0 END) AS value,
	d.start_date,
	d.end_date
FROM 
	dates d
	JOIN transactions t ON TRUE
	JOIN splits s ON t.guid = s.tx_guid
	JOIN accounts a ON a.guid = s.account_guid
WHERE
	a.account_type = 'CASH'
	AND t.guid NOT IN (SELECT t.guid FROM transactions t JOIN splits s ON t.guid = s.tx_guid JOIN accounts a ON a.guid = s.account_guid WHERE a.account_type = 'EQUITY')
GROUP BY 
	a.guid, d.start_date, d.end_date
ORDER BY
	a.guid, d.start_date
)

SELECT
	coa.account_guid,
	coa.main_account_type,
	coa.account_name,
	coa.account_code,
	coa.account_depth_level,
	coa.account_level1,
	coa.account_level2,
	coa.account_level3,
	coa.account_level4,
	coa.account_level5,
	coa.account_level6,
	ROUND(ism.value,2) * -1 AS value,
	ism.start_date,
	(ism.end_date - INTERVAL '1 Day') :: DATE AS end_date
FROM
	income_statement_monthly ism
	JOIN chart_of_accounts coa ON coa.account_guid = ism.account_guid
ORDER BY
	account_code, account_name, end_date;