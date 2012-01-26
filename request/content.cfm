<cffunction name="content" access="private" returntype="void">
	<cfargument name="type" type="string" required="true">

	<cfcontent type="#arguments.type#">
</cffunction>