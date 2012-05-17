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
 * The DebugTask is a decorator that is used when in debug mode.
 **/
component DebugTask implements="Task" {

	public void function init(required Task task, required struct metadata) {

		variables.task = arguments.task;
		variables.metadata = StructCopy(arguments.metadata);
		variables.metadata.type = getType();

	}

	public boolean function run(required Event event) {

		success = true;

		if (!arguments.event.isAborted()) {
			arguments.event.record(variables.metadata, "cflow.task");

			success = variables.task.run(arguments.event);

			arguments.event.record(variables.metadata, "cflow.task");
		}

		return success;
	}

	public string function getType() {
		return variables.task.getType();
	}

	public void function addSubtask(required Task task) {
		variables.task.addSubtask(arguments.task);
	}

}