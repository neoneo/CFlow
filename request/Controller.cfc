component Controller {

	public void function init(required Context context) {

		variables.context = context;
		// keep a cache of dispatch tasks
		variables.dispatchTasks = {};

	}

	private boolean function dispatchEvent(required string type, required Event event) {

		var targetName = arguments.event.getTarget();

		if (!StructKeyExists(variables.dispatchTasks, targetName)) {
			variables.dispatchTasks[targetName] = {};
		}
		if (!StructKeyExists(variables.dispatchTasks[targetName], arguments.type)) {
			variables.dispatchTasks[targetName][arguments.type] = variables.context.createDispatchTask(targetName, arguments.type, false);
		}

		// the dispatch task cancels our event if it fails, but we want the controller to do that (or not)
		// so we pass a clone of the task
		return variables.dispatchTasks[targetName][arguments.type].run(arguments.event.clone());
	}

}