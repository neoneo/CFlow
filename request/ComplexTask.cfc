/**
 * A ComplexTask is a task that can have subtasks. When these subtasks are run is up to the implementation.
 **/
component ComplexTask implements="Task" {

	variables.subtasks = [];

	public boolean function run(required Event event) {
		throw(type = "cflow", message = "Not implemented");
	}

	public void function addSubtask(required Task task) {
		ArrayAppend(variables.subtasks, arguments.task);
	}

	private boolean function runSubtasks(required Event event) {

		var success = true;
		for (var task in variables.subtasks) {
			success = task.run(arguments.event);
			if (!success) {
				break;
			}
		}

		return success;
	}

	private boolean function hasSubtasks() {
		return !ArrayIsEmpty(variables.subtasks);
	}

}