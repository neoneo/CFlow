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

	public void function init(required component controller, required string handlerName) {
		variables.controller = arguments.controller;
		variables.handlerName = arguments.handlerName;
	}

	public boolean function run(required Event event) {

		Invoke(variables.controller, variables.handlerName, {1 = arguments.event});

		var canceled = arguments.event.isCanceled();
		var aborted = arguments.event.isAborted();

		if (canceled && !aborted) {
			arguments.event.revert();
			runSubtasks(arguments.event);
		}

		return !canceled && !aborted;
	}

	public string function getType() {
		return "invoke";
	}

}