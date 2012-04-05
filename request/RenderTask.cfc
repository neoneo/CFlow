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

component RenderTask implements="Task" {

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

	public boolean function run(required Event event) {

		// call render() in order to hide the event object
		render(arguments.event.getProperties(), arguments.event.getResponse());

		return true;
	}

	public string function getType() {
		return "render";
	}

	private void function render(required struct data, required Response response) {

		// create variables for use within the view
		StructAppend(local, arguments.data, true);
		local.response = arguments.response;

		// set the content key, so that response.append() calls without a key argument will write to this view
		response.setContentKey(variables.key);

		var template = variables.view & ".cfm";
		savecontent variable="local.content" {
			include template;
		}

		// depending on the content key is not thread safe, so we pass the key explicitly
		response.append(local.content, variables.key);

	}

	/**
	 * Shorthand for accessing the writeUrl() method on the request manager.
	 * This method is available in views.
	 **/
	private string function writeUrl(required string target, required string event, struct parameters) {
		return variables.requestStrategy.writeUrl(argumentCollection = arguments);
	}

}