<!--- Set page processing time to 1 minute  --->
<cfsetting requesttimeout="120">

<title>ORM File Builder</title>

<cfparam name="URL.tables" default="">
<cfparam name="URL.datasource" default="">

<cfif URL.datasource EQ "">
	Please specify the URL parameters for;<br/>  
	<b>'datasource'</b> and optionally specify the <b>'tables'</b> and <b>'create_files'</b>. <br><br>
	Note: If no tables are specified all will be returned. <br>
	'create_files' will actually create the ORM files in this codebase at ~\application\ORM\{orm_file_name}.cfc. So you can copy this folder into your app and setup ORM acccordingly.
	<cfabort>
</cfif>

<cfif isDefined("URL.create_files")>
	<cfset URL.create_files = true>
<cfelse>
	<cfset URL.create_files = false>
</cfif>

<!--- Do we want to create/recreate the actually ORM files? --->
<cfif URL.create_files>
	<cfset base_path = getDirectoryFromPath(getCurrentTemplatePath())>
	<cfset orm_folder_path = base_path & 'application\ORM\'>

	<cfif !directoryExists(orm_folder_path)>
		<cfset directoryCreate(orm_folder_path)>
	</cfif>
</cfif>


<!--- See code-prettify here - https://github.com/google/code-prettify --->
<script src="https://cdn.rawgit.com/google/code-prettify/master/loader/run_prettify.js"></script>
<!--- Dark Theme for code-pretty --->
<link rel="stylesheet" href="https://cdn.rawgit.com/google/code-prettify/760e6e73/styles/desert.css" />
<style>pre{white-space: pre-wrap;}</style> <!--- Allow <pre> element to wrap if necessary --->


<!--- Assume we only listed DB tables to begin with --->
<cfset all_tables = false>

<cfif URL.tables EQ "">
	<cfset all_tables = true>

	<!--- Get ALL table names --->
	<cfquery name="qry_tableNames" datasource="#URL.datasource#">
		SELECT 	name
		FROM 	sys.tables
		WHERE 	type = 'U'
		AND 	name != 'sysdiagrams'
	</cfquery>

	<cfset URL.tables = valueList(qry_tableNames.name)>
</cfif>

<cfif all_tables>
	<h3>ORM Code for all database tables</h3>
<cfelse>
	<h3>ORM Code for database tables;</h3>
</cfif>	

<cfset sql_in_clause = "">
<cfset first = true>

<!--- Output numbered list and create SQL IN clause --->
<ol>
	<cfloop list="#URL.tables#" index="i">
		<cfif !first>
			<cfset sql_in_clause &= ",'" & i & "'">
		<cfelse>
			<cfset sql_in_clause &= "'" & i & "'">
			<cfset first = false>
		</cfif>	
		
		<!--- Only Output this only if all_tables is false. IE. If the user has specified tables in the URL param --->
		<cfif !all_tables>
			<cfoutput><li>#i#</li></cfoutput>
		</cfif>
	</cfloop>
</ol>	

<br/><br/>


<cfquery name="qry_tableNames" datasource="#URL.datasource#">
	SELECT 	name
	FROM 	sys.tables
	WHERE 	type = 'U'
	AND		name IN (#preserveSingleQuotes(sql_in_clause)#)
</cfquery>

<!--- <cfdump var="#qry_tableNames#"> --->


<!--- Loop through tables to get column names --->
<cfoutput query="qry_tableNames">
	<!--- Get column names for this table --->
	<cfquery name="qry_tableColumns" datasource="#URL.datasource#">
		SELECT 	column_name, is_nullable
		FROM 	information_schema.columns
		WHERE 	table_name = '#qry_tableNames.name#'
	</cfquery>

	<!--- Dump columns per table
	<cfdump var="#qry_tableColumns#"> --->


	<!--- Get primary key of this table (if any). If it is a junction/bus table (with no PK) so it should be skipped --->
	<cfset pk_column_name = getPrimaryKey(qry_tableNames.name)>
	
	<!--- If this table has a PK proceed --->
	<cfif pk_column_name NEQ ''>

		<!--- Start the <cfcomponent> --->
		<cfset ormCode = '&lt;cfcomponent persistent="true"&gt;'>

		<!--- Set empty strings for the relationshiops. These will be populated if relationships are found --->
		<cfset fk_relationships = ''> <!--- many-to-one --->
		<cfset pk_relationships_one_to_many = ''> 
		<cfset pk_relationships_many_to_many = ''>
		

		<b title="ORM component file should be named '#qry_tableNames.name#.cfc'">#qry_tableNames.currentrow#: #qry_tableNames.name#.cfc</b>

		<!--- Loop through the table columns --->
		<cfloop query="qry_tableColumns">
			
			<!--- check if this column has any FK relations (many-to-one) --->
			<cfset qry_FK_col_relationship = checkRelationship( qry_tableNames.name, qry_tableColumns.column_name, 'FK' )>
			
			<!--- If there are no foreign keys for this column so output the standard <cfproperty> element --->
			<cfif qry_FK_col_relationship.recordcount EQ 0>
				<!--- Start the <cfproperty> tag --->
				<cfset ormCode &= '<br>&##9;&lt;cfproperty name="' & qry_tableColumns.column_name & '"'>
				
				<!--- If this is the PK for this table then output the extra PK attributes --->
				<cfif qry_tableColumns.column_name EQ pk_column_name>
					<!--- Add the attributes for the PK column --->
					<cfset ormCode &= ' fieldtype="id" generator="native"'>						
				</cfif>
				
				<!--- If this column is nullable then add notnull="false". This allows default null values to be saved to the DB. Otherwise you have to insert a value --->
				<cfif qry_tableColumns.is_nullable EQ 'YES'>
					<!--- Add the attributes for the PK column --->
					<cfset ormCode &= ' notnull=false default="" hint="For nullable columns notnull=false allows default null values to be saved to the DB. Otherwise you have to insert a value. default="" returns [empty string] for DB records with {null}"'>						
				</cfif>
				
				<!--- Close the <cfproperty> --->
				<cfset ormCode &= '&gt;'>
			

			<!--- This column has a FK relationship so output the <cfproperty> relationship --->
			<cfelse>

				<!--- Output a CF comment with the basic <cfproperty> in case a user doesn't want to use the relationship below --->
				<cfset fk_relationships &= '<br>&##9;&lt;!--- &lt;cfproperty name="' & qry_tableColumns.column_name & '"&gt; ---&gt;'>

				<!--- <cfproperty name="Message" fieldtype="many-to-one" cfc="de_msgs_new" fkcolumn="msg_id"> --->
				<cfset fk_relationships &= '<br>&##9;&lt;cfproperty name="' & TitleCase(qry_tableColumns.column_name) & '" fieldtype="many-to-one" ' >
				<cfset fk_relationships &= 'cfc="' & qry_FK_col_relationship.PK_table & '" fkcolumn="' & qry_FK_col_relationship.FK_column & '"' >
				<cfset fk_relationships &= '&gt;'>
			</cfif>	
			

			<!--- Check if this column has any PK relations. These can be one-to-many and many-to-many --->
			<cfset qry_PK_col_relationships = checkRelationship( qry_tableNames.name, qry_tableColumns.column_name, 'PK')>
			
			<!--- Loop over any PK relationships found --->
			<cfloop query="qry_PK_col_relationships">

				<!--- To find out if the the relationship is a one-to-many or many-to-many (junction/bus) table we check if the ADJOINING table has a PK or not. 
					If no PK is found it is a bus table --->
				<cfset pk_column_exists = getPrimaryKey(qry_PK_col_relationships.FK_table)>
				
				<!--- If PK of adjoining table we can assume it is a many-to-many (junction/bus) table --->
				<cfif pk_column_exists EQ "">
			
					<!--- As this is a junction/bus table we need to get the details of the joining table on the other side --->
					<!--- <cfset qry_many_to_many_joining_table = checkRelationship( qry_PK_col_relationships.FK_table, qry_PK_col_relationships.PK_column, qry_tableNames.name)> --->
					<cfset qry_many_to_many_joining_table = checkRelationship( qry_PK_col_relationships.FK_table, qry_PK_col_relationships.PK_column, 'many-to-many', qry_tableNames.name)>

					<!--- <br>
					<cfdump var="#qry_PK_col_relationships.FK_table#"><br>
					<cfdump var="#qry_PK_col_relationships.PK_column#"><br>
					<cfdump var="#qry_many_to_many_joining_table#"> --->


					<!--- Detailed <cfproperty name="FDI" fieldtype="many-to-many" cfc="fdi" linktable="de_msgs_fdi"      fkcolumn="msg_id" inversejoincolumn="fdi_id"> --->
					<!--- Simple <cfproperty name="FDI" fieldtype="many-to-many" cfc="fdi" linktable="de_msgs_fdi"> --->
					<cfset pk_relationships_many_to_many &= '<br>&##9;&lt;cfproperty name="' & TitleCase(qry_PK_col_relationships.FK_table) & '" fieldtype="many-to-many" ' >
					<cfset pk_relationships_many_to_many &= 'cfc="' & qry_many_to_many_joining_table.PK_table & '" linktable="' & qry_PK_col_relationships.FK_table & '" '>
					<!--- This line may note be required. It is only if the column names in the junction/bus table don't match the PK table --->
					<cfset pk_relationships_many_to_many &= 'fkcolumn="' & qry_PK_col_relationships.FK_column & '" inversejoincolumn="' & qry_many_to_many_joining_table.FK_column & '"'>
					<!--- Close the <cfproperty> relationship --->
					<cfset pk_relationships_many_to_many &= '&gt;'>	


				<cfelse> <!--- Adjoining table has a PK so this is treated a a one-to-many join --->
					<cfset pk_relationships_one_to_many &= '<br>&##9;&lt;cfproperty name="' & TitleCase(qry_PK_col_relationships.FK_table) & '" fieldtype="one-to-many" ' >
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

		<!--- Add the many-to-many relationships --->
		<cfif pk_relationships_one_to_many NEQ ''>
			<!--- Output a CF comment --->
			<cfset ormCode &= '<br><br>&##9;&lt;!--- PK "one-to-many" Relationships ---&gt;'>
			
			<!--- Add one-to-many relationships (if any) --->
			<cfset ormCode &= pk_relationships_one_to_many>
		</cfif>

		<!--- Add the many-to-many relationships (if any) --->
		<cfif pk_relationships_many_to_many NEQ ''>
			<!--- Output a CF comment --->
			<cfset ormCode &= '<br><br>&##9;&lt;!--- PK "many-to-many" (junction/bus) Relationships'>
			<cfset ormCode &= '<br>&##9;Note that the "fkcolumn" and "inversejoincolumn" attributes below are required only if <br>&##9;they column names in the junction/bus table do not match the column names in the corresponding PK/FK tables ---&gt;'>
			
			<!--- Add many-to-many relationships --->
			<cfset ormCode &= pk_relationships_many_to_many>
		</cfif>


		<!--- Close the component tag --->
		<cfset ormCode &= '<br>&lt;/cfcomponent&gt;'>

		<!--- The below code is placed within a <pre> tag to allow it to be copied as is into cfc file without any formatting changes needed --->
		<pre class="prettyprint lang-html">#ormCode#</pre>

		<!--- Create the file if the URL var  --->
		<cfif URL.create_files>
			<cfset orm_file_path = orm_folder_path & qry_tableNames.name & '.cfc'>
			
			<!--- Translate the HTML output code to CF code --->
			<cfset ormCode = replace(ormCode, '&lt;', '<', 'all')>
			<cfset ormCode = replace(ormCode, '&gt;', '>', 'all')>
			<cfset ormCode = replace(ormCode, '<br>',  Chr(13) & Chr(10), 'all')>
			<cfset ormCode = replace(ormCode, '&##9;',  Chr(9), 'all')>

			<cfset fileWrite(orm_file_path, ormCode)>
			<p>ORM file has been created at <b>#orm_file_path#</b></p>
		</cfif>	
		<!--- <hr /> --->
		<br><br>

	</cfif> <!--- End check for table PK --->

</cfoutput>




<!--- Functions --->
<!--- Functions --->
<!--- Functions --->
<cffunction name="getPrimaryKey" returntype="string">
	<cfargument name="table" type="string">

	<cfquery name="LOCAL.qry" datasource="#URL.datasource#">
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
	<cfargument name="type" type="string" required="false" default="">
	<cfargument name="original_table" type="string" required="false" default="" hint="Used for many-to-many">

	<!--- Get relationships --->
	<cfquery name="LOCAL.qry" datasource="#URL.datasource#">
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
			WHERE 	o1.name = '#ARGUMENTS.table#'
			AND 	c1.name = '#ARGUMENTS.column#'
		
		<cfelseif ARGUMENTS.type EQ "PK">
			WHERE 	o2.name = '#ARGUMENTS.table#'
			AND 	c2.name = '#ARGUMENTS.column#'

		<cfelseif ARGUMENTS.type EQ "many-to-many">
			WHERE 	o1.name = '#ARGUMENTS.table#'
			AND 	c2.name = '#ARGUMENTS.column#'
			AND 	o2.name != '#ARGUMENTS.original_table#'
		</cfif>
	</cfquery>

	<cfreturn LOCAL.qry>
</cffunction>


<cffunction name="TitleCase" hint="This function is used to create TitleCased relationship names based on the names of the column or table (whichever is applicable)">
	<cfargument name="val" type="string">

	<cfset ARGUMENTS.val = REReplace(ARGUMENTS.val, "_", " ", "all")>
	<cfset ARGUMENTS.val = REReplace(ARGUMENTS.val, "\b(\S)(\S*)\b", "\u\1\L\2", "all")>
	<cfset ARGUMENTS.val = REReplace(ARGUMENTS.val, " ", "", "all")>
	<cfset ARGUMENTS.val = right(ARGUMENTS.val, 2) NEQ "id" ? ARGUMENTS.val : left(ARGUMENTS.val, len(ARGUMENTS.val) - 2 ) >

	<cfreturn ARGUMENTS.val>
</cffunction>	
