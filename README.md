CFML_ORM_Code_generator
=======================

CFML ORM Code generator that loops through the system tables tables in a MSSQL DB. It finds any defined relationships and outputs copyable code required to create all of your ORM CFC files.

Notes;
1. `datasource` is the only required paramater. 
2. The Relationships are named based on the tables (for one-to-many and many-to-many) or column name (for many-to-one).
3. For any Relationships defined you will of course have to create the associated ORM file for that relationship

Example output with two tables in the URL;
![alt text](https://user-images.githubusercontent.com/1670634/28962729-896cd2a4-78fe-11e7-96f5-770bcb9c8029.jpg)

Add URL params (datasource, tables) to get ORM code for the desired tables. Example; ~/?datasource=eveara&tables=albums,tracks

