component InvokeTask extends="ComplexTask" {

	public void function init(required Controller controller, required string method) {
		variables.controller = arguments.controller;
		variables.method = arguments.method;
	}

	public boolean function process(required Event event) {

		getController()[getMethod()](arguments.event);

		var success = !arguments.event.isCanceled();
		if (!success) {
			processSubtasks(arguments.event.clone());
		}

		return success;
	}

	private Controller function getController() {
		return variables.controller;
	}

	private string function getMethod() {
		return variables.method;
	}

}