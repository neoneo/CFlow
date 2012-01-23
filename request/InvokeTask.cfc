component InvokeTask extends="ComplexTask" {

	if (!StructKeyExists(GetFunctionList(), "invoke")) {
		include "invoke.cfm";
	}

	public void function init(required Controller controller, required string method) {

		variables.controller = arguments.controller;
		variables.method = arguments.method;

	}

	public boolean function run(required Event event) {

		Invoke(getController(), getMethod(), arguments);

		var success = !arguments.event.isCanceled();
		if (!success) {
			if (hasSubtasks()) {
				runSubtasks(arguments.event.clone());
			}
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