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

component ThreadTask extends="ComplexTask" {

	public void function init(string action = "run", string name = "", string priority = "normal", numeric timeout = 0) {

		variables.action = arguments.action;
		variables.name = arguments.name;
		variables.priority = arguments.priority;
		variables.timeout = arguments.timeout;

		if (arguments.action == "join") {
			// convert the names list into an array for easy looping later
			variables.names = ListToArray(arguments.name);
		}

	}

	public boolean function run(required Event event, required Response response) {

		switch (variables.action) {
			case "run":
				// run the subtasks within the thread
				thread action="run" name="#variables.name#" priority="#variables.priority#" event="#arguments.event#" response="#arguments.response#" {
					// for thread safety, the thread gets its own event and response objects
					runSubtasks(attributes.event, attributes.response);
				};
				break;

			case "join":
				thread action="join" name="#variables.name#" timeout="#variables.timeout#";
				for (var name in variables.names) {
					if (cfthread[name].status == "completed") {
						// merge the event objects of the threads on the current event object (without overwriting)
						arguments.event.setProperties(cfthread[name].event.getProperties());
						// merging the response objects is more difficult: setType(), write() and clear() all interfere
						// for now ignore the thread's response object
					}
				}
				break;

			case "terminate":
				thread action="terminate" name="#variables.name#";
				break;

		}

		return true; // no canceling or aborting the current event is possible within a thread
	}

	public string function getType() {
		return "thread";
	}

	public void function addSubtask(required Task task) {
		// subtasks only have meaning if action = run
		if (variables.action != "run") {
			Throw(type = "cflow.request", message = "Thread task with action '#variables.action#' cannot contain subtasks");
		}

		super.addSubtask(arguments.task);

	}

}