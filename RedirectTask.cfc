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

	public void function init(string location = "", string target = "", string event = "", struct parameters = {}, boolean permanent = false, EndPoint endPoint) {

		if (Len(arguments.location) > 0) {
			variables.isEventRedirect = false;
			variables.location =  new Parameter(arguments.location);
		} else {
			variables.isEventRedirect = true;
			// the request strategy should be present, target and event keys are optional in parameters
			variables.endPoint = arguments.endPoint;
			variables.target = new Parameter(arguments.target);
			variables.event = new Parameter(arguments.event);
		}

		// handle runtime parameters if present
		variables.parameters = {};
		for (var name in arguments.parameters) {
			// store the parameter in a Parameter instance; that instance will determine whether the value should be taken literally or be evaluated
			variables.parameters[name] = new Parameter(arguments.parameters[name]);
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

		local.location = "";
		var parameters = {};
		// get the values for the parameters to append on the url
		for (var name in variables.parameters) {
			// get the value using the event
			parameters[name] = variables.parameters[name].getValue(arguments.event);
		}

		if (variables.isEventRedirect) {
			local.location = variables.endPoint.createURL(variables.target.getValue(arguments.event), variables.event.getValue(arguments.event), parameters);
		} else {
			local.location = variables.location.getValue(arguments.event);
			// only append if there are parameters
			if (!StructIsEmpty(parameters)) {
				local.location &= (local.location contains "?" ? "&" : "?");
				var queryString = "";
				for (var name in parameters) {
					queryString = ListAppend(queryString, name & "=" & UrlEncodedFormat(parameters[name]), "&");
				}
				local.location &= queryString;
			}
		}

		return local.location;
	}

}