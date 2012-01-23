<cffunction name="invoke" access="private" output="false" returntype="any">
	<cfargument name="component" type="component" required="true">
	<cfargument name="method" type="string" required="true">
	<cfargument name="argumentCollection" type="struct" required="true">

	<cfinvoke component="#arguments.component#" method="#arguments.method#" argumentCollection="#arguments.argumentCollection#" returnvariable="result"></cfinvoke>

</cffunction>