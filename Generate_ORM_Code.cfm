<!---
	DataSource - If application.data_source is not already set in your Application.cfc set it here as queries below are based on it 
--->

<!--- Get table names for the current DB --->
<cfquery name="qry_tableNames">
	select name
	from sys.tables
	where type = 'U'
</cfquery>

<!--- <cfdump var="#qry_tableNames#"> --->

<!--- Loop through tables to get column names --->
<cfloop query="qry_tableNames">
	<!--- Get column names --->
	<cfquery name="qry_tableColumns">
		select column_name
		from information_schema.columns
		where table_name = '#qry_tableNames.name#'
	</cfquery>

	<!--- Dump columns per table
	<cfdump var="#qry_tableColumns#"> --->

	<!--- Output code for the ORM file --->
	<cfset first = true> <!--- Use this to make the primary key special --->

	<cfoutput>
		<cfsavecontent variable="ormCode">
			<h3>ORM code for table: #qry_tableNames.name#</h3>
			<h4>
				File should be named #qry_tableNames.name#.cfc<br />
				Note: Relationships (if any) will need to be manually added
			</h4>

<!--- The below code is placed within a <pre> tag to allow it to be copied as is into cfc file without any  --->
<pre>
&lt;cfcomponent persistent="true"&gt;<cfloop query="qry_tableColumns"><br>&##9;&lt;cfproperty name="#qry_tableColumns.column_name#"<cfif first> fieldtype="id" generator="native"<cfset first = false></cfif>&gt;</cfloop>
&lt;/cfcomponent&gt;
</pre>
		</cfsavecontent>

		#ormCode#
	</cfoutput>

	<br /><br /><br />
</cfloop>
