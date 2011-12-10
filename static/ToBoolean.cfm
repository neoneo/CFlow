<cffunction name="ToBoolean" access="private" output="false" returntype="boolean" hint="Converts any value to a boolean.">
	<cfargument name="value" type="any" required="true">

	<cfset var result=false>

	<cfif IsSimpleValue(arguments.value)>
		<cfset arguments.value=Trim(arguments.value)>
		<cfif IsBoolean(arguments.value)>
			<!--- the value can be converted natively --->
			<cfset result=YesNoFormat(arguments.value)>
		<cfelse>
			<!--- the result is true if the value is not empty --->
			<cfset result=Len(arguments.value) gt 0>
		</cfif>
	<cfelse>
		<!--- all complex values return true --->
		<cfset result=true>
	</cfif>

	<cfreturn result>
</cffunction>