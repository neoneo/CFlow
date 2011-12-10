<cffunction name="ToCFSQLType" access="private" output="false" returntype="string">
	<cfargument name="datatype" type="string" required="true">

	<cfset var sqltype="">
	<cfswitch expression="#arguments.datatype#">
		<cfcase value="datetime,smalldatetime"><cfset sqltype="cf_sql_timestamp"></cfcase>
		<cfcase value="tinyint"><cfset sqltype="cf_sql_tinyint"></cfcase>
		<cfcase value="smallint"><cfset sqltype="cf_sql_smallint"></cfcase>
		<cfcase value="int,mediumint"><cfset sqltype="cf_sql_integer"></cfcase>
		<cfcase value="bigint"><cfset sqltype="cf_sql_bigint"></cfcase>
		<cfcase value="decimal,float"><cfset sqltype="cf_sql_decimal"></cfcase>
		<cfcase value="bit"><cfset sqltype="cf_sql_bit"></cfcase>
		<cfcase value="uniqueidentifier"><cfset sqltype="cf_sql_idstamp"></cfcase>
		<cfdefaultcase><cfset sqltype="cf_sql_varchar"></cfdefaultcase>
	</cfswitch>

	<cfreturn sqltype>
</cffunction>
