<cffunction name="inject" access="private" output="false" returntype="void" hint="Injects static methods into components.">
	<cfargument name="methodName" type="string" required="true">

	<cfif not StructKeyExists(variables,arguments.methodName) and not StructKeyExists(GetFunctionList(),arguments.methodName)>
		<cfinclude template="/CFlow/static/#arguments.methodName#.cfm">
	</cfif>

</cffunction>