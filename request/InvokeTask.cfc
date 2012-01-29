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

component InvokeTask extends="ComplexTask" {

	if (!StructKeyExists(GetFunctionList(), "invoke")) {
		include "invoke.cfm";
	}

	public void function init(required Controller controller, required string method) {

		variables.controller = arguments.controller;
		variables.method = arguments.method;

	}

	public boolean function run(required Event event) {

		Invoke(getController(), getMethod(), arguments);

		var success = !arguments.event.isCanceled();
		if (!success) {
			if (hasSubtasks()) {
				runSubtasks(arguments.event.clone());
			}
		}

		return success;
	}

	private Controller function getController() {
		return variables.controller;
	}

	private string function getMethod() {
		return variables.method;
	}

}