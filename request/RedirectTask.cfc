/*
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
*/

component RedirectTask implements="Task" {

	public void function init(string url = "", string target = "", required string event = "", struct parameters = {}, boolean permanent = false, RequestStrategy requestStrategy) {

		if (Len(arguments.url) > 0) {
			variables.isEventRedirect = false;
			variables.url =  new cflow.util.Parameter(arguments.url);
		} else {
			variables.isEventRedirect = true;
			// the request strategy should be present, target and event keys are optional in parameters
			variables.requestStrategy = arguments.requestStrategy;
			variables.target = new cflow.util.Parameter(arguments.target);
			variables.event = new cflow.util.Parameter(arguments.event);
		}

		// handle runtime parameters if present
		variables.parameters = {};
		for (var name in arguments.parameters) {
			// store the parameter in a Parameter instance; that instance will determine whether the value should be taken literally or be evaluated
			variables.parameters[name] = new cflow.util.Parameter(arguments.parameters[name]);
		}

		if (arguments.permanent) {
			variables.statusCode = 301;
		} else {
			variables.statusCode = 302;
		}

	}

	public boolean function run(required Event event) {

		Location(obtainUrl(arguments.event), false, variables.statusCode);

		return true;
	}

	public string function getType() {
		return "redirect";
	}

	public string function obtainUrl(required Event event) {

		local.url = "";
		var parameters = {};
		// get the values for the parameters to append on the url
		for (var name in variables.parameters) {
			// get the value using the event
			parameters[name] = variables.parameters[name].getValue(arguments.event);
		}

		if (variables.isEventRedirect) {
			local.url = variables.requestStrategy.writeUrl(variables.target.getValue(arguments.event), variables.event.getValue(arguments.event), parameters);
		} else {
			local.url = variables.url.getValue(arguments.event);
			// only append if there are parameters
			if (!StructIsEmpty(parameters)) {
				if (local.url does not contain "?") {
					local.url &= "?";
				}
				var queryString = "";
				for (var name in parameters) {
					queryString = ListAppend(queryString, name & "=" & UrlEncodedFormat(parameters[name]), "&");
				}
				local.url &= queryString;
			}
		}

		return local.url;
	}

}