/*
Gnucash - SQL Financial Reports

This projects aims to develop custom Gnucash reports based on PostgreSQL server. Gnucash reports may have limited reports options and lack of individual analyze abilities. Therefore, created custom SQL reports to deep or custom analyze the data in Gnucash.

>[!CAUTION]
> These queries are not official queries, made it by intermediate SQL knowledges. Therefore, calculation may wrong, you have to test your data before use it.

![](https://i.imgur.com/q8GE9ze.png)
Github --> https://github.com/anilakdereli
*/
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

chart_of_accounts AS (
	WITH RECURSIVE accounthierarchy AS ( 
SELECT 
	a.guid,
	a.parent_guid,
	a.name AS name,
	a.name :: TEXT AS account_path,
	0 AS depth_level
FROM
	accounts a
WHERE
	a.parent_guid IS NULL

UNION ALL

SELECT 
	a.guid,
	a.parent_guid,
	a.name,
	(ah.account_path || ':') || a.name AS account_path,
	ah.depth_level + 1 AS depth_level
FROM
	accounts a
	JOIN accounthierarchy ah ON a.parent_guid = ah.guid
)

SELECT
	ac.guid AS account_guid,
	a.commodity_guid,
	CASE
		WHEN a.account_type IN ('RECEIVABLE', 'BANK', 'CASH', 'MUTUAL', 'STOCK', 'TRADING') THEN 'ASSET'
		WHEN a.account_type IN ('PAYABLE', 'CREDIT') THEN 'LIABILITY'
		ELSE a.account_type
	END AS main_account_type,
	a.account_type,
	ac.account_path,
	ac.depth_level AS account_depth_level,
	a.name AS account_name,
	a.code AS account_code,
	c.mnemonic AS currency,
	split_part(ac.account_path, ':', 2) AS account_level1,
	split_part(ac.account_path, ':', 3) AS account_level2,
	split_part(ac.account_path, ':', 4) AS account_level3,
	split_part(ac.account_path, ':', 5) AS account_level4,
	split_part(ac.account_path, ':', 6) AS account_level5,
	split_part(ac.account_path, ':', 7) AS account_level6

FROM
	accounthierarchy ac
	JOIN accounts a ON a.guid = ac.guid
	JOIN commodities c ON c.guid = a.commodity_guid
WHERE
	ac.parent_guid IS NOT NULL
ORDER BY
	a.code, main_account_type, ac.account_path
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
	a.account_type IN ('INCOME', 'EXPENSE')
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