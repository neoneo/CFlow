component AbstractTask implements="Task" {

	variables.subtasks = [];

	/*public boolean function process(required Event event, required Response response) {
		throw(type="cflow", message="Not implemented");
	}*/

	public void function addSubtask(required Task task) {
		ArrayAppend(variables.subtasks, arguments.task);
	}

	private boolean function processSubtasks(required Event event, required Response response) {

		var success = true;
		for (var task in variables.subtasks) {
			success = task.process(arguments.event, arguments.response);
			if (!success) {
				break;
			}
		}

		return success;
	}

}