<cffunction name="StructKeyValuePairs" access="private" output="false" returntype="struct" hint="Accepts arguments in pairs and uses odd numbered ones as keys, and even numbered ones as values. This function maintains case.">

	<cfset var result=StructNew()>
	<cfset var i=0>

	<cfloop from="1" to="#ArrayLen(arguments)#" index="i" step="2">
		<cfset StructInsert(result,arguments[i],arguments[i+1],true)>
	</cfloop>

	<cfreturn result>
</cffunction>