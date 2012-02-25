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
		variables.metadata = arguments.metadata;
		StructAppend(variables.metadata, {type = GetMetaData(variables.task).name});

	}

	public boolean function run(required Event event) {

		success = true;

		if (!arguments.event.isAborted()) {
			arguments.event.record("cflow.task", variables.metadata);

			success = variables.task.run(arguments.event);

			arguments.event.record("cflow.task", variables.metadata);
		}

		return success;
	}

	public void function addSubtask(required Task task) {
		variables.task.addSubtask(arguments.task);
	}

}