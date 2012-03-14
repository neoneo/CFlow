<!---
   Copyright 2012 Neo Neo

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
--->

<cffunction name="invoke" access="private" output="false" returntype="any">
	<cfargument name="component" type="component" required="true">
	<cfargument name="method" type="string" required="true">
	<cfargument name="argumentCollection" type="struct" required="false" default="#{}#">

	<cfinvoke component="#arguments.component#" method="#arguments.method#" argumentCollection="#arguments.argumentCollection#" returnvariable="local.result"></cfinvoke>

	<cfif StructKeyExists(local, "result")>
		<cfreturn local.result>
	</cfif>
</cffunction>