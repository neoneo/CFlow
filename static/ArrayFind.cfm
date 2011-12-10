<cffunction name="ArrayFind" access="private" output="false" returntype="numeric" hint="Searches the given array and returns the position where the given string is found.">
	<cfargument name="array" type="array" required="true">
	<cfargument name="value" type="string" required="true">

	<cfset var index=0>
	<cfset var i=0>

	<cfloop from="1" to="#ArrayLen(arguments.array)#" index="i">
		<cfif arguments.array[i] eq arguments.value>
			<cfset index=i>
			<cfbreak>
		</cfif>
	</cfloop>

	<cfreturn index>
</cffunction>