<cffunction name="GetSQLStatement" access="private" output="false" returntype="string" hint="Returns the issued SQL statement for the given query object.">
	<cfargument name="query" type="query" required="true">

	<cfset var statement="">
	<cfset var metaData="">
	<cfset var parameter="">

	<cfswitch expression="#Server.ColdFusion.ProductName#">
		<cfcase value="ColdFusion Server">
			<cfset metaData=arguments.query.getMetaData().getExtendedMetaData()>
			<cfset statement=metaData.sql>
			<cfif StructKeyExists(metaData,"sqlparameters")>
				<cfloop array="#metaData.sqlparameters#" index="parameter">
					<cfset statement=Replace(statement,"?","'" & Replace(parameter,"'","''","all") & "'","one")>
				</cfloop>
			</cfif>
		</cfcase>
		<cfcase value="Railo">
			<cfset statement=arguments.query.getSQL().toString()>
		</cfcase>
		<cfdefaultcase>
			<cfthrow message="Unsupported ColdFusion runtime">
		</cfdefaultcase>
	</cfswitch>

	<cfreturn statement>
</cffunction>