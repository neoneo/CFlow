component DispatchTask extends="ComplexTask" {

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

	private Context function getContext() {
		return variables.context;
	}

}