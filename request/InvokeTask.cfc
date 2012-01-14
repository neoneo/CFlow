component InvokeTask extends="AbstractTask" {

	public void function init(required component controller, required string method) {
		variables.controller = arguments.controller;
		variables.method = arguments.method;
	}

	public boolean function process(required Event event, required Response response) {

		variables.controller[variables.method](arguments.event);

		var success = !arguments.event.isCanceled();
		if (!success) {
			processSubtasks(arguments.event.clone(), arguments.response);
		}

		return success;
	}

}