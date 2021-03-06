CFML ORM File generator & builder
=================================

CFML ORM Code generator that loops through the system tables tables in a MSSQL DB. It finds any defined relationships and outputs copyable code required to create all of your ORM CFC files.

Notes;
1. `datasource` is the only required URL paramater. 
2. `tables` and `create_files` are optional URL paramaters. If `tables` is not specified the code will return output for all DB tables. Be careful if your database is large as this could require a lot of processing power. If the `create_files` paramater is defined the ORM files will actually be created at ~\application\ORM\{dynamic_orm_file_name}.cfc
3. The Relationships are named, in TitleCase, based on the table name (for one-to-many and many-to-many relationships) or column name (for many-to-one).
4. For any Relationships defined you will of course have to create the associated ORM file for that relationship.

Example output with two tables in the URL;
![alt text](https://user-images.githubusercontent.com/1670634/31280689-13c4c84e-aaa5-11e7-9748-0cc1fbd8a4c5.png)

