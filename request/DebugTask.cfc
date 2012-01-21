/**
 * The DebugTask is a decorator that is used when in debug mode.
 **/
component DebugTask implements="Task" {

	public void function init(required Task task, required struct metadata) {

		variables.task = arguments.task;
		variables.metadata = arguments.metadata;

	}

	public boolean function process(required Event event) {

		ArrayAppend(arguments.event.debugInformation, {
			"message" = "taskStart",
			"target" = arguments.event.getTarget(),
			"event" = arguments.event.getType(),
			"type" = GetMetaData(variables.task).name,
			"metadata" = variables.metadata,
			"tickcount" = GetTickCount()
		});

		var success = variables.task.process(arguments.event);

		ArrayAppend(arguments.event.debugInformation, {
			"message" = "taskEnd",
			"target" = arguments.event.getTarget(),
			"event" = arguments.event.getType(),
			"type" = GetMetaData(variables.task).name,
			"metadata" = variables.metadata,
			"tickcount" = GetTickCount()
		});

		return success;
	}

	public void function addSubtask(required Task task) {
		variables.task.addSubtask(arguments.task);
	}

}