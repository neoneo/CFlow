<cffunction name="Collection" access="private" output="false" returntype="struct">
	<!--- the arguments collection can be accessed both as a regular and an associative array --->
	<!--- this feature is retained when we just return it --->
	<cfreturn arguments>
</cffunction>