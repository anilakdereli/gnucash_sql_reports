/*
# Gnucash - SQL Financial Reports

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

dates AS(
SELECT
	generate_series(gnucash_date + INTERVAL '1 Month', current_date + INTERVAL '1 Month', '1 Month') AS date
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

prices_monthly AS (
SELECT 
	commodity_guid,
	mnemonic,
	value,
	date
FROM(
	SELECT
		c.guid AS commodity_guid,
		c.mnemonic,
		p.value_num * 1.0 / p.value_denom
		*
		COALESCE((SELECT p2.value_num * 1.0 / p2.value_denom FROM prices p2 WHERE p2.date <= p.date AND c2.guid = p2.commodity_guid ORDER BY p2.date DESC LIMIT 1), 1) AS value,
		p.date,
		row_number() OVER (PARTITION BY date_trunc('month', p.date), c.guid 
		ORDER BY p.date DESC) AS row_num
	FROM
		prices p
		JOIN commodities c ON c.guid = p.commodity_guid
		JOIN commodities c2 ON c2.guid = p.currency_guid
	ORDER BY
		c.mnemonic, p.date
) t
WHERE row_num = 1
),

balance_sheet_monthly AS(
SELECT
	a.guid AS account_guid,
	SUM(CASE WHEN t.post_date < d.date THEN s.quantity_num * 1.0 / s.quantity_denom ELSE 0 END)
	* COALESCE((
	SELECT
			pm.value
	FROM prices_monthly pm
	WHERE pm.commodity_guid = a.commodity_guid AND pm.date < d.date
	ORDER BY pm.date DESC
	LIMIT 1)
	,1) AS value,
	d.date
FROM 
	dates d
	JOIN transactions t ON true
	LEFT JOIN splits s ON t.guid = s.tx_guid
	LEFT JOIN accounts a ON a.guid = s.account_guid
WHERE 
	a.account_type NOT IN ('INCOME', 'EXPENSE')
GROUP BY 
	a.guid, d.date
ORDER BY
	 a.guid, d.date
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
	ROUND(bsm.value, 2) AS value,
	bsm.date
FROM
	balance_sheet_monthly bsm
	JOIN chart_of_accounts coa ON coa.account_guid = bsm.account_guid
ORDER BY
	coa.account_code, date;
