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

<cfcomponent displayname="RenderTask" implements="Task" output="false">

	<cfscript>
	public void function init(required string view, string mapping = "", RequestStrategy requestStrategy) {

		variables.view = arguments.view;
		if (Len(arguments.mapping) > 0) {
			// prepend the given mapping
			variables.view = arguments.mapping & "/" & variables.view;
		}
		// use the view without the mapping for the response key
		variables.key = arguments.view;

		variables.requestStrategy = arguments.requestStrategy;

	}

	public boolean function run(required Event event, required Response response) {

		render(arguments.event.getProperties(), arguments.response);

		return true;
	}

	public string function getType() {
		return "render";
	}
	</cfscript>

	<cffunction name="render" access="private" output="false" returntype="void">
		<cfargument name="data" type="struct" required="true">
		<cfargument name="response" type="Response" required="true">

		<!--- set the content key, so that response.append() calls without a key argument will write to this view --->
		<cfset arguments.response.setContentKey(variables.key)>

		<cfsavecontent variable="local.content">
			<cfmodule template="render.cfm" view="#variables.view#.cfm" response="#arguments.response#" data="#arguments.data#" requeststrategy="#variables.requestStrategy#">
		</cfsavecontent>

		<!--- depending on the content key is not thread safe, so we pass the key explicitly --->
		<cfset response.append(local.content, variables.key)>

	</cffunction>

</cfcomponent>