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

component DispatchTask extends="ComplexTask" {

	/**
	 * Constructor.
	 *
	 * @param	{Context}	context			the context of the application
	 * @param	{String}	targetName		the target of the event to dispatch
	 * @param	{String}	eventType		the type of the event to dispatch
	 **/
	public void function init(required Context context, required string targetName, required string eventType) {

		variables.context = arguments.context;
		variables.targetName = new cflow.util.Parameter(arguments.targetName);
		variables.eventType = new cflow.util.Parameter(arguments.eventType);

	}

	public boolean function run(required Event event) {

		// get the target and event from the respective parameters
		var targetName = getTargetName(arguments.event);
		var eventType = getEventType(arguments.event);

		variables.context.dispatchEvent(arguments.event, targetName, eventType);
		var canceled = arguments.event.isCanceled();
		var aborted = arguments.event.isAborted();

		if (canceled && !aborted) {
			arguments.event.revert();
			runSubtasks(arguments.event);
			arguments.event.cancel();
		}

		return !canceled && !aborted;
	}

	public string function getType() {
		return "dispatch";
	}

	public string function getTargetName(required Event event) {
		return variables.targetName.getValue(arguments.event);
	}

	public string function getEventType(required Event event) {
		return variables.eventType.getValue(arguments.event);
	}

}