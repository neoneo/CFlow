component DispatchTask extends="ComplexTask" {

	public void function init(required Context context, required string targetName, required string eventType) {
		variables.context = arguments.context;
		variables.targetName = arguments.targetName;
		variables.eventType = arguments.eventType;
	}

	public boolean function process(required Event event) {

		// create a new event object with the properties of the event object that is passed in
		var dispatch = getContext().createEvent(variables.targetName, variables.eventType, arguments.event);

		var success = getContext().dispatchEvent(dispatch);

		if (!success) {
			arguments.event.cancel();
			processSubtasks(arguments.event.clone());
		}

		return success;
	}

	private Context function getContext() {
		return variables.context;
	}

}