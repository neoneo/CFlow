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

	//if (!StructKeyExists(GetFunctionList(), "invoke")) {
		//include "../static/invoke.cfm";
	//}

	public void function init(required component controller, required string method) {

		variables.controller = arguments.controller;
		variables.method = arguments.method;

	}

	public boolean function run(required Event event, required Response response) {

		//invokeMethod(variables.controller, variables.method, arguments);
		variables.controller[variables.method](arguments.event);

		var canceled = arguments.event.isCanceled();
		var aborted = arguments.event.isAborted();

		if (canceled && !aborted) {
			arguments.event.reset();
			runSubtasks(arguments.event, arguments.response);
		}

		return !canceled && !aborted;
	}

	public string function getType() {
		return "invoke";
	}

}