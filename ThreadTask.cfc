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

	public void function init(required Context context, string action = "run", string name = "", string priority = "normal", numeric timeout = 0, numeric duration = 0) {

		variables.context = arguments.context;
		variables.action = arguments.action;
		variables.name = arguments.name;
		variables.priority = arguments.priority;
		variables.timeout = arguments.timeout;
		variables.duration = arguments.duration;

		if (arguments.action == "join") {
			// convert the names list into an array for easy looping later
			variables.names = ListToArray(arguments.name);
		}

	}

	public boolean function run(required Event event) {

		switch (variables.action) {
			case "run":
				// run the subtasks within the thread
				// for thread safety, the thread gets its own event object
				thread action="run" name="#variables.name#" priority="#variables.priority#" properties="#arguments.event.getProperties()#" target="#arguments.event.getTarget()#" event="#arguments.event.getType()#" {
					// create a new event object based on the attributes
					// these object is not passed in as an attribute, because we need a clean instance
					// there is also a railo bug: https://issues.jboss.org/browse/RAILO-1926 (which is not going to be solved)
					thread.event = variables.context.createEvent(attributes.target, attributes.event, attributes.properties);
					thread.event.setRejoin(false);
					runSubtasks(thread.event);
				};
				break;

			case "join":
				// tell the threads that they will be joined
				// structs in the thread scope of other threads become writable after the first join action expires
				// TODO: find out if this is correct behavior
				// http://groups.google.com/group/railo/browse_thread/thread/3618c8f24da6eed0
				thread action="join" name="#variables.name#" timeout="1";
				for (var name in variables.names) {
					switch (cfthread[name].status) {
						case "running":
						case "not_started":
							cfthread[name].event.setRejoin(true);
							break;
					}
				}

				thread action="join" name="#variables.name#" timeout="#variables.timeout#";

				for (var name in variables.names) {
					switch (cfthread[name].status) {
						case "completed":
						case "running":
							// merge the event objects of the threads on the current event object
							arguments.event.merge(cfthread[name].event);

						// no break statement
						case "not_started":
							// tell the thread that the join action has timed out
							cfthread[name].event.setRejoin(false);
							break;
					}
				}
				break;

			case "terminate":
				thread action="terminate" name="#variables.name#";
				break;

			case "sleep":
				thread action="sleep" duration="#variables.duration#";
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
			Throw(type = "cflow", message = "Thread task with action '#variables.action#' cannot contain subtasks");
		}

		super.addSubtask(arguments.task);

	}

}