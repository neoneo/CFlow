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

/**
 * A ComplexTask is a task that can have subtasks. When these subtasks are run is up to the implementation.
 **/
component ComplexTask implements="Task" {

	variables.subtasks = [];

	public boolean function run(required Event event, required Response response) {
		Throw(type = "cflow.notimplemented", message = "Not implemented");
	}

	public string function getType() {
		Throw(type = "cflow.notimplemented", message = "Not implemented");
	}

	public void function addSubtask(required Task task) {
		ArrayAppend(variables.subtasks, arguments.task);
	}

	private boolean function runSubtasks(required Event event, required Response response) {

		var success = true; // if a task has no subtasks, we want the flow to proceed
		for (var task in variables.subtasks) {
			success = task.run(arguments.event, arguments.response);
			if (!success) {
				break;
			}
		}

		return success;
	}

}