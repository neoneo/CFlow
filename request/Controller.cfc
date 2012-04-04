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

component Controller {

	public void function init(required Context context) {

		variables.context = context;
		// keep a cache of dispatch tasks
		variables.dispatchTasks = {};

	}

	private boolean function dispatchEvent(required string type, required Event event) {

		if (!StructKeyExists(variables.dispatchTasks, arguments.type)) {
			// pass false to the factory method: we don't want the current event to be canceled if the dispatched event is canceled
			// the controller implementation should be able to choose to do that
			variables.dispatchTasks[arguments.type] = variables.context.createDispatchTask(arguments.event.getTarget(), arguments.type, false);
		}

		return variables.dispatchTasks[arguments.type].run(arguments.event);
	}

}