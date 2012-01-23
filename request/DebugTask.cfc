/**
 * The DebugTask is a decorator that is used when in debug mode.
 **/
component DebugTask implements="Task" {

	public void function init(required Task task, required struct metadata) {

		variables.task = arguments.task;
		variables.metadata = arguments.metadata;
		StructAppend(variables.metadata, {type = GetMetaData(variables.task).name});

	}

	public boolean function run(required Event event) {

		arguments.event.record("task", variables.metadata);

		var success = variables.task.run(arguments.event);

		arguments.event.record("task", variables.metadata);

		return success;
	}

	public void function addSubtask(required Task task) {
		variables.task.addSubtask(arguments.task);
	}

}