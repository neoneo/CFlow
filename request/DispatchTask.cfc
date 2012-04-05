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
	 * @param	{Boolean}	cancelFailed	if true, cancels the originating event if the dispatched event is canceled
	 **/
	public void function init(required Context context, required string targetName, required string eventType, boolean cancelFailed = true) {

		variables.context = arguments.context;
		variables.targetName = arguments.targetName;
		variables.eventType = arguments.eventType;
		variables.cancelFailed = arguments.cancelFailed;

	}

	public boolean function run(required Event event) {

		// create a new event object with the properties of the event object that is passed in
		var dispatch = getContext().createEvent(variables.targetName, variables.eventType, arguments.event); //.getProperties(), arguments.event.getResponse());

		var success = getContext().dispatchEvent(dispatch);

		if (!success && variables.cancelFailed) {
			if (hasSubtasks()) {
				runSubtasks(arguments.event.clone());
			}
			arguments.event.cancel();
		}

		return success;
	}

	public string function getType() {
		return "dispatch";
	}


	private Context function getContext() {
		return variables.context;
	}

}