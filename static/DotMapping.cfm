<cffunction name="DotMapping" access="private" output="false" returntype="string">
	<cfargument name="mapping" type="string" required="true">

	<cfset var dotMapping=REReplace(arguments.mapping,"(\\|/)",".","all")>
	<cfif Left(dotMapping,1) eq ".">
		<cfset dotMapping=RemoveChars(dotMapping,1,1)>
	</cfif>
	<cfif Right(dotMapping,1) eq ".">
		<cfset dotMapping=Left(dotMapping,Len(dotMapping)-1)>
	</cfif>

	<cfreturn dotMapping>
</cffunction>