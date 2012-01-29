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

		var targetName = arguments.event.getTarget();

		if (!StructKeyExists(variables.dispatchTasks, targetName)) {
			variables.dispatchTasks[targetName] = {};
		}
		if (!StructKeyExists(variables.dispatchTasks[targetName], arguments.type)) {
			variables.dispatchTasks[targetName][arguments.type] = variables.context.createDispatchTask(targetName, arguments.type, false);
		}

		// the dispatch task cancels our event if it fails, but we want the controller to do that (or not)
		// so we pass a clone of the task
		return variables.dispatchTasks[targetName][arguments.type].run(arguments.event.clone());
	}

}