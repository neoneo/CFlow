<!---
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
--->

component DebugThreadTask extends="ThreadTask" {

	public void function init(required Context context, string action = "run", string name = "", string priority = "normal", numeric timeout = 0) {

		variables.metadata = StructCopy(arguments);
		StructDelete(variables.metadata, "context");
		variables.metadata.type = getType();
		super.init(argumentCollection = arguments);

	}

	public boolean function run(required Event event, required Response response) {

		success = true;

		if (!arguments.event.isAborted()) {
			var metadata = StructCopy(variables.metadata);

			arguments.event.record(metadata, "cflow.task");

			success = super.run(arguments.event, arguments.response);

			// if this is a join action, merge the event messages on the current event object
			if (variables.metadata.action == "join") {
				// loop over the joined threads
				var names = ListToArray(variables.metadata.name);
				for (var name in names) {
					// pick up the messages from the thread event object
					arguments.event.record({
						name = name,
						messages = cfthread[name].event.getMessages()
					}, "cflow.thread");
				}
			}

			arguments.event.record(metadata, "cflow.task");
		}

		return success;
	}

	/*private boolean function runSubtasks(required Event event, required Response response) {

		// this method is invoked from within the thread
		try {
			super.runSubtasks(arguments.event, arguments.response);
		} catch (any e) {
			// record the exception, in case the thread is joined by the page thread later
			arguments.event.record({exception: e}, "cflow.exception");
			// rethrow, so the thread exits with the same status code
			rethrow;
		}

	}*/

}