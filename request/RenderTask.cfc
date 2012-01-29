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

	public void function init(required string template) {

		variables.template = arguments.template;

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

		savecontent variable="local.content" {
			include variables.template & ".cfm";
		}

		response.write(content);

	}

}