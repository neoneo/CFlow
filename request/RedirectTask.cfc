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

	/**
	 * Constructor.
	 * type				url or event; determines which parameters are expected
	 * parameters		if the type is url, a url key is required; for event, target and event keys are optional
	 * 					additionally, for both types a parameters struct is optional, which contains additional querystring parameters
	 * permanent		whether this is a permanent redirect or not
	 * requestStrategy	the request strategy, only required when type is event
	 **/
	public void function init(required string type, required struct parameters = {}, boolean permanent = false, RequestStrategy requestStrategy) {

		variables.type = arguments.type;

		switch (variables.type) {
			case "url":
				// the url key should be present
				variables.urlString = arguments.parameters.url;
				break;

			case "event":
				variables.urlString = "";

				// the request strategy should be present, target and event keys are optional in parameters
				variables.requestStrategy = arguments.requestStrategy;
				variables.target = StructKeyExists(arguments.parameters, "target") ? arguments.parameters.target : "";
				variables.event = StructKeyExists(arguments.parameters, "event") ? arguments.parameters.event : "";
				break;
		}

		variables.generate = false; // generate the url at runtime?

		// handle runtime parameters if present
		if (StructKeyExists(arguments.parameters, "parameters")) {
			variables.generate = true;
			// this should be an array of parameters to be evaluated at runtime
			// a parameter can be a single name, in which case the parameter name and value are taken from the event as is
			// optionally, they can have the form '<name1>=<name2>', where name1 gives the name of the parameter and name2 gives the value (if it exists on the event)
			// convert them all to the same form
			local.parameters = [];
			for (var parameter in arguments.parameters.parameters) {
				var transport = {};
				if (ListLen(parameter, "=") > 1) {
					transport.name = Trim(ListFirst(parameter, "="));
					transport.value = Trim(ListLast(parameter, "="));
				} else {
					// name and value are the same
					transport.name = Trim(parameter);
					transport.value = Trim(parameter);
				}
				ArrayAppend(local.parameters, transport);
			}
			variables.parameters = local.parameters;
		} else {
			// no runtime parameters
			if (variables.type == "event") {
				// the url is always the same, so we can generate it now
				variables.urlString = arguments.requestStrategy.writeUrl(variables.target, variables.event);
			}
		}

		if (arguments.permanent) {
			variables.statusCode = 301;
		} else {
			variables.statusCode = 302;
		}

	}

	public boolean function run(required Event event, required Response response) {

		Location(obtainUrl(arguments.event), false, variables.statusCode);

		return true;
	}

	public string function getType() {
		return "redirect";
	}

	private string function obtainUrl(required Event event) {

		var urlString = variables.urlString;

		if (variables.generate) {
			// we have to append runtime parameters onto the url
			var parameters = {};
			for (var parameter in variables.parameters) {
				if (StructKeyExists(arguments.event, parameter.value)) {
					parameters[parameter.name] = arguments.event[parameter.value];
				}
			}

			switch (variables.type) {
				case "url":
					if (!StructIsEmpty(parameters)) {
						if (urlString does not contain "?") {
							urlString &= "?";
						}
						for (var parameter in parameters) {
							urlString = ListAppend(urlString, parameter & "=" & UrlEncodedFormat(parameters[parameter]), "&");
						}
					}

					break;

				case "event":
					urlString = variables.requestStrategy.writeUrl(variables.target, variables.event, parameters);
					break;
			}
		}

		return urlString;
	}

}