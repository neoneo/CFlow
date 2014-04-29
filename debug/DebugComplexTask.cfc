component DebugComplexTask extends="DebugTask" {

	public void function addSubtask(required Task task) {
		variables.task.addSubtask(arguments.task);
	}

}