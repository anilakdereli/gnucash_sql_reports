# Gnucash - Financial Statement SQL Queries

Hi!

I was not comfortable with Gnucash reports. Therefore, I was searching another solutions which fits my needs. I found the solution with PostgreSQL & Apache Superset (BI/Dashboard Tool).

I needed to write SQL queries own my own with my intermediate SQL knowledge. Anyway, I wanted to share the codes to may help other people too. I hope it helps! :)

If there is something wrong, you may correct me or if you have any suggestions, I would like to listen to it.

There are 3 view:

1. Chart of Accounts

2. Balance Sheet (Monthly) --> Prices calculated as most recent to report date.

3. Income Statement (Monthly)

==NOTE: Calculations may wrong, you should test your data before use it.==


## How to use?

1. Copy paste all codes one by one which is starting with 'Chart of Accounts'
2. Select the views created. Example: ``` SELECT * FROM balance_sheet_monthly ```
