<cffunction name="GetClassName" access="private" output="false" returntype="string" hint="Returns the classname of the ColdFusion component or the Java object.">
	<cfargument name="instance" type="any" required="true">

	<cfset var metaData=GetMetaData(arguments.instance)>
	<cfset var className="">

	<cfif StructKeyExists(metaData,"fullname")>
		<!--- ColdFusion component --->
		<cfset className=metaData.fullname>
	<cfelseif StructKeyExists(metaData,"class")>
		<!--- java object --->
		<cfset className=metaData.class>
	</cfif>

	<cfreturn className>
</cffunction>