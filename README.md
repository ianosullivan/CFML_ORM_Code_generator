CFML_ORM_Code_generator
=======================

CFML ORM Code generator that loops through the system tables tables in a MSSQL DB. It finds any defined relationships and outputs copyable code required to create all of your ORM CFC files.

Notes;
1. `datasource` is the only required URL paramater. `tables` is an optional list URL paramater. If not specified the code will return output for all DB tables. Be careful if your database is large as this could require a lot of processing power.
2. The Relationships are named, in TitleCase, based on the table name (for one-to-many and many-to-many relationships) or column name (for many-to-one).
3. For any Relationships defined you will of course have to create the associated ORM file for that relationship.

Example output with two tables in the URL;
![alt text](https://user-images.githubusercontent.com/1670634/31280689-13c4c84e-aaa5-11e7-9748-0cc1fbd8a4c5.png)

