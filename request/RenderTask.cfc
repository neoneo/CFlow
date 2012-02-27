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

	public void function init(required string template, required RequestManager requestManager) {

		variables.template = arguments.template;
		variables.requestManager = arguments.requestManager;

	}

	public boolean function run(required Event event) {

		// call render() in order to hide the event object
		render(arguments.event.getProperties(), arguments.event.getResponse());

		return true;
	}

	private void function render(required struct properties, required Response response) {

		// create the following variables for use within the template
		var properties = arguments.properties;
		var response = arguments.response;

		// set the content key, so that any response.append() calls will write to this view
		response.setContentKey(variables.template);

		savecontent variable="local.content" {
			include variables.template & ".cfm";
		}

		// depending on the content key is not thread safe, so we pass the key explicitly
		response.append(content, variables.template);

	}

	/**
	 * Shorthand for accessing the writeUrl() method on the request manager.
	 * This method is available in views.
	 **/
	private string function writeUrl(required string target, required string event, struct parameters) {
		return variables.requestManager.writeUrl(argumentCollection = arguments);
	}

}