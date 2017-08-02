<!---
	DataSource - If application.data_source is not already set in your Application.cfc set it here as queries below are based on it 
--->

<cfparam name="URL.tables" default="">


<!--- See code-prettify here - https://github.com/google/code-prettify --->
<script src="https://cdn.rawgit.com/google/code-prettify/master/loader/run_prettify.js"></script>
<!--- Dark Theme for code-pretty --->
<link rel="stylesheet" href="https://cdn.rawgit.com/google/code-prettify/760e6e73/styles/desert.css" />
<style>white-space: pre-wrap;</style> <!--- Allow <pre> element to wrap if necessary --->

<!--- Get ALL table names --->
<cfif tables EQ "">
	<cfquery name="qry_tableNames">
		SELECT 	name
		FROM 	sys.tables
		WHERE 	type = 'U'
	</cfquery>

	<h3>ORM Code for ALL Tables</h3>

<cfelse> <!--- Get specific table names --->

	<h3>ORM Code for Tables;</h3>

	<cfset sql_in_clause = "">
	<cfset first = true>
	
	<!--- Output numbered list and  --->
	<ol>
		<cfloop list="#URL.tables#" index="i">
			<cfif !first>
				<cfset sql_in_clause &= ",'" & i & "'">
			<cfelse>
				<cfset sql_in_clause &= "'" & i & "'">
				<cfset first = false>
			</cfif>	

			<cfoutput><li>#i#</li></cfoutput>
		</cfloop>
	</ol>	


	<cfquery name="qry_tableNames">
		SELECT 	name
		FROM 	sys.tables
		WHERE 	type = 'U'
		AND		name IN (#preserveSingleQuotes(sql_in_clause)#)
	</cfquery>

	<!--- <cfdump var="#qry_tableNames#"> --->

</cfif>
<hr/>
<br/><br/>

<!--- Loop through tables to get column names --->
<cfoutput query="qry_tableNames">
	<!--- Get column names for this table --->
	<cfquery name="qry_tableColumns">
		SELECT 	column_name
		FROM 	information_schema.columns
		WHERE 	table_name = '#qry_tableNames.name#'
	</cfquery>

	<!--- Dump columns per table
	<cfdump var="#qry_tableColumns#"> --->


	<b title="ORM component file should be named '#qry_tableNames.name#.cfc'">#qry_tableNames.currentrow#: #qry_tableNames.name#.cfc</b>

	<!--- Start the <cfcomponent> --->
	<cfset ormCode = '&lt;cfcomponent persistent="true"&gt;'>

	<!--- Set empty strings for the relationshiops. These will be populated if relationships are found --->
	<cfset fk_relationships = ''> <!--- many-to-one --->
	<cfset pk_relationships_one_to_many = ''> 
	<cfset pk_relationships_many_to_many = ''>
	
	<!--- Get primary key of this table --->
	<cfset pk_column_name = getPrimaryKey(qry_tableNames.name)>

	<!--- Loop through the table columns --->
	<cfloop query="qry_tableColumns">
		
		<!--- check if this column has any FK relations (many-to-one) --->
		<cfset qry_FK_col_relationship = checkRelationship( qry_tableNames.name, qry_tableColumns.column_name, 'FK')>
		
		<!--- If there are no foreign keys for this column so output the standard <cfproperty> element --->
		<cfif qry_FK_col_relationship.recordcount EQ 0>
			<!--- Start the <cfproperty> tag --->
			<cfset ormCode &= '<br>&##9;&lt;cfproperty name="' & qry_tableColumns.column_name & '"'>
				
				<!--- If this is the PK for this table then output the extra PK attributes --->
				<cfif qry_tableColumns.column_name EQ pk_column_name>
					<!--- Add the attributes for the PK column --->
					<cfset ormCode &= ' fieldtype="id" generator="native"'>						
				</cfif>
			
			<!--- Close the <cfproperty> --->
			<cfset ormCode &= '&gt;'>
		

		<!--- This column has a FK relationship so output the <cfproperty> relationship --->
		<cfelse>

			<!--- Output a CF comment with the basic <cfproperty> in case a user doesn't want to use the relationship below --->
			<cfset fk_relationships &= '<br>&##9;&lt;!--- &lt;cfproperty name="' & qry_tableColumns.column_name & '"&gt; ---&gt;'>

			<!--- <cfproperty name="Message" fieldtype="many-to-one" cfc="de_msgs_new" fkcolumn="msg_id"> --->
			<cfset fk_relationships &= '<br>&##9;&lt;cfproperty name="' & uCase(qry_FK_col_relationship.PK_table) & '" fieldtype="many-to-one" ' >
			<cfset fk_relationships &= 'cfc="' & qry_FK_col_relationship.PK_table & '" fkcolumn="' & qry_FK_col_relationship.FK_column & '"' >
			<cfset fk_relationships &= '&gt;'>
		</cfif>	
		

		<!--- Check if this column has any standard PK relations. These can be one-to-many and many-to-many --->
		<cfset qry_PK_col_relationships = checkRelationship( qry_tableNames.name, qry_tableColumns.column_name, 'PK')>
		
		<!--- Loop over any PK relationships found --->
		<cfloop query="qry_PK_col_relationships">

			<!--- To find out if the the relationship is a one-to-many or many-to-many (junction/bus) table we check if the ADJOINING table has a PK or not. 
				If no PK is found it is a bus table --->
			<cfset pk_column_exists = getPrimaryKey(qry_PK_col_relationships.FK_table)>
			
			<!--- If PK of adjoining table we can assume it is a many-to-many (junction/bus) table --->
			<cfif pk_column_exists EQ "">
		
<!--- Todo: Many-to-many --->
<!--- Todo: Many-to-many --->
<!--- Todo: Many-to-many --->

			<cfelse> <!--- Adjoining table has a PK so this is treated a a one-to-many join --->
				<cfset pk_relationships_one_to_many &= '<br>&##9;&lt;cfproperty name="' & uCase(qry_PK_col_relationships.FK_table) & '" fieldtype="one-to-many" ' >
				<cfset pk_relationships_one_to_many &= 'cfc="' & qry_PK_col_relationships.FK_table & '" fkcolumn="' & qry_PK_col_relationships.FK_column & '"' >
				<cfset pk_relationships_one_to_many &= '&gt;'>			
			</cfif>
		</cfloop>

	</cfloop>
	
	<!--- Add the FK relationships (if any) --->
	<cfif fk_relationships NEQ ''>
		<!--- Output a CF comment --->
		<cfset ormCode &= '<br><br>&##9;&lt;!--- FK Relationships ---&gt;'>
		
		<!--- Add FK relations --->
		<cfset ormCode &= fk_relationships>
	</cfif>

	<!--- Add the PK (one-to-many) --->
	<cfif pk_relationships_one_to_many NEQ ''>
		<!--- Output a CF comment --->
		<cfset ormCode &= '<br><br>&##9;&lt;!--- PK (one-to-many) Relationships ---&gt;'>
		
		<!--- Add one-to-many relationships --->
		<cfset ormCode &= pk_relationships_one_to_many>
	</cfif>


	<!--- Close the component tag --->
	<cfset ormCode &= '<br>&lt;/cfcomponent&gt;'>

	<!--- The below code is placed within a <pre> tag to allow it to be copied as is into cfc file without any formatting changes needed --->
	<pre class="prettyprint lang-html">#ormCode#</pre>

	<!--- <hr /> --->
	<br><br>
</cfoutput>


<!--- Functions --->
<!--- Functions --->
<!--- Functions --->
<cffunction name="getPrimaryKey" returntype="string">
	<cfargument name="table" type="string">

	<cfquery name="LOCAL.qry">
		SELECT  OBJECT_NAME(ic.OBJECT_ID) AS table_name,
		        COL_NAME(ic.OBJECT_ID,ic.column_id) AS pk_column_name
		FROM    sys.indexes AS i 
		JOIN 	sys.index_columns AS ic ON  i.OBJECT_ID = ic.OBJECT_ID AND i.index_id = ic.index_id
		WHERE   i.is_primary_key = 1
    	AND     OBJECT_NAME(ic.OBJECT_ID) = '#ARGUMENTS.table#'
	</cfquery>
	
	<cfif LOCAL.qry.recordcount EQ 1>
		<cfreturn LOCAL.qry.pk_column_name>
	<cfelse>
		<cfreturn "">
	</cfif>
</cffunction>


<cffunction name="checkRelationship" returntype="query">
	<cfargument name="table" type="string">
	<cfargument name="column" type="string">
	<cfargument name="type" type="string">

	<!--- Get relationships --->
	<cfquery name="LOCAL.qry">
		SELECT
		    o1.name AS FK_table,
		    c1.name AS FK_column,
		    -- fk.name AS FK_name,
		    o2.name AS PK_table,
		    c2.name AS PK_column,
		    -- pk.name AS PK_name,
		    fk.delete_referential_action_desc AS Delete_Action,
		    fk.update_referential_action_desc AS Update_Action
		FROM sys.objects o1
		    INNER JOIN sys.foreign_keys fk
		        ON o1.object_id = fk.parent_object_id
		    INNER JOIN sys.foreign_key_columns fkc
		        ON fk.object_id = fkc.constraint_object_id
		    INNER JOIN sys.columns c1
		        ON fkc.parent_object_id = c1.object_id
		        AND fkc.parent_column_id = c1.column_id
		    INNER JOIN sys.columns c2
		        ON fkc.referenced_object_id = c2.object_id
		        AND fkc.referenced_column_id = c2.column_id
		    INNER JOIN sys.objects o2
		        ON fk.referenced_object_id = o2.object_id
		    INNER JOIN sys.key_constraints pk
		        ON fk.referenced_object_id = pk.parent_object_id
		        AND fk.key_index_id = pk.unique_index_id
		
		<!--- What type of relationship --->
		<cfif ARGUMENTS.type EQ "FK">
			WHERE o1.name = '#ARGUMENTS.table#'
			AND c1.name = '#ARGUMENTS.column#'
		
		<cfelseif ARGUMENTS.type EQ "PK">
			WHERE o2.name = '#ARGUMENTS.table#'
			AND c2.name = '#ARGUMENTS.column#'

		</cfif>
	</cfquery>

	<cfreturn LOCAL.qry>
</cffunction>


<!--- <cfdump var="#checkRelationship('de_msg_recipients', 'msg_id', 'FK')#"> --->
