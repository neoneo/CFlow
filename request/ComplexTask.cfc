/**
 * A ComplexTask is a task that can have subtasks. When these subtasks are processed is up to the implementation.
 **/
component ComplexTask implements="Task" {

	variables.subtasks = [];

	public boolean function process(required Event event) {
		throw(type="cflow", message="Not implemented");
	}

	public void function addSubtask(required Task task) {
		ArrayAppend(variables.subtasks, arguments.task);
	}

	package boolean function hasSubtasks() {
		return !ArrayIsEmpty(variables.subtasks);
	}

	private boolean function processSubtasks(required Event event) {

		var success = true;
		for (var task in variables.subtasks) {
			success = task.process(arguments.event);
			if (!success) {
				break;
			}
		}

		return success;
	}

}