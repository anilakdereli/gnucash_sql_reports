/*
# Gnucash - SQL Financial Reports

This projects aims to develop custom Gnucash reports based on PostgreSQL server. Gnucash reports may have limited reports options and lack of individual analyze abilities. Therefore, created custom SQL reports to deep or custom analyze the data in Gnucash.

>[!CAUTION]
> These queries are not official queries, made it by intermediate SQL knowledges. Therefore, calculation may wrong, you have to test your data before use it.

![](https://i.imgur.com/q8GE9ze.png)
Github --> https://github.com/anilakdereli
*/

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
	a.code, main_account_type, ac.account_path;