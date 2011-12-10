<cffunction name="Array" access="private" output="false" returntype="array">

	<cfset var result=ArrayNew(1)>

	<cfloop array="#arguments#" index="item">
		<cfset ArrayAppend(result,item)>
	</cfloop>

	<cfreturn result>
</cffunction>