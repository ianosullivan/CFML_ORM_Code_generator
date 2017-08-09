CFML_ORM_Code_generator
=======================

CFML ORM Code generator that loops through the system tables tables in a MSSQL DB. It finds any defined relationships and outputs copyable code for each ORM CFC file.

Note that the Relationships are named nased on the tables so you will probably want to rename these to something more suitable.
I am planning to add a form to show you all the tables within the DB. This will allow you to select the tables and can then create the ORM files in a specified location.

Example output with two tables in the URL;
![alt text](https://user-images.githubusercontent.com/1670634/28962729-896cd2a4-78fe-11e7-96f5-770bcb9c8029.jpg)

Add URL params (datasource, tables) to get ORM code for the desired tables. Example; ~/?datasource=eveara&tables=albums,tracks

