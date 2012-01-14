component DispatchTask extends="AbstractTask" {

	public void function init(required Context context, required string targetName, required string eventType) {
		variables.context = arguments.context;
		variables.targetName = arguments.targetName;
		variables.eventType = arguments.eventType;
	}

	public boolean function process(required Event event, required Response response) {

		// create a new event object with the properties of the event object that is passed in
		var dispatch = new Event(variables.targetName, variables.eventType, arguments.event.getProperties());

		var success = getContext().dispatchEvent(dispatch, arguments.response);

		if (!success) {
			arguments.event.cancel();
			processSubtasks(arguments.event.clone(), arguments.response);
		}

		return success;
	}

}