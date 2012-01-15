component Controller {

	public void function init(required Context context) {
		variables.context = context;
	}

	private boolean function dispatchEvent(required string type, required Event event) {

		var task = variables.context.createDispatchTask(arguments.event.getTarget(), arguments.type);

		return task.process(arguments.event);
	}

}