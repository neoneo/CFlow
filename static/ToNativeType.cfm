<cffunction name="ToNativeType" access="private" output="false" returntype="string" hint="Converts an SQL datatype to its native ColdFusion counterpart.">
	<cfargument name="datatype" type="string" required="true">

	<cfset var type="">
	<cfswitch expression="#arguments.datatype#">
		<cfcase value="tinyint,smallint,int,bigint,decimal,float,numeric,real">
			<cfset type="numeric">
		</cfcase>
		<cfcase value="datetime,smalldatetime">
			<cfset type="date">
		</cfcase>
		<cfcase value="bit">
			<cfset type="boolean">
		</cfcase>
		<cfcase value="uniqueidentifier">
			<cfset type="guid">
		</cfcase>
		<cfdefaultcase>
			<cfset type="string">
		</cfdefaultcase>
	</cfswitch>

	<cfreturn type>
</cffunction>