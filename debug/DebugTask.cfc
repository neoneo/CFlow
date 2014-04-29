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

import cflow.Context;
import cflow.Task;
import cflow.Event;

/**
 * Task is a decorator that is used when in debug mode.
 **/
component DebugTask implements="cflow.Task" {

	public void function init(required Task task, required struct metadata, required Context context) {

		variables.task = arguments.task;
		variables.metadata = StructCopy(arguments.metadata);
		variables.metadata.type = getType();
		variables.context = arguments.context;

	}

	public boolean function run(required Event event) {

		var success = false;

		// create a copy of the metadata struct
		// subclasses must be allowed to modify it before or after the task runs
		var metadata = StructCopy(variables.metadata);
		recordStart(arguments.event, metadata);

		try {
			success = variables.task.run(arguments.event);
		} catch (any exception) {
			// the exception may have been rethrown by a subtask, in which case the event is aborted already
			if (!arguments.event.isAborted()) {
				arguments.event.record({exception = exception}, "cflow.exception");
				arguments.event.getResponse().clear();
				arguments.event.abort();
			}
			// rethrow the exception in order to exit the flow
			rethrow;
		} finally {
			recordEnd(arguments.event, metadata);
		}

		return success;
	}

	public string function getType() {
		return variables.task.getType();
	}

	private void function recordStart(required Event event, required struct metadata) {
		arguments.event.recordStart(arguments.metadata, "cflow.task");
	}

	private void function recordEnd(required Event event, required struct metadata) {
		// metadata is not used, but can be used by subclasses
		arguments.event.recordEnd();
	}

}