<cfset variables.generator=CreateObject("java","java.util.UUID")>

<cffunction name="CreateGuid" access="private" output="false" returntype="guid">
	<cfreturn variables.generator.randomUUID().toString()>
	<!--- <cfreturn Insert("-",CreateUUID(),23)> --->
</cffunction>