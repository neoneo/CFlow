<cffunction name="ListDeleteLast" access="private" output="false" returntype="string">
	<cfargument name="list" type="string" required="true">
	<cfargument name="delimiter" type="string" required="false" default=",">

	<cfreturn ListDeleteAt(arguments.list,ListLen(arguments.list,arguments.delimiter),arguments.delimiter)>
</cffunction>