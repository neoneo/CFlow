component Processor {

	public void function init(required Context context) {
		variables.context = arguments.context;
		variables.factory = variables.context; //.getFactory();
		variables.response = variables.factory.createResponse();

		variables.controllers = {};
		variables.debug = getContext().getSetting("debug");
	}

	/**
	 * Processes the tasks using the event.
	 **/
	public boolean function processEvent(required string targetName, required string eventType, struct properties = {}) {

		var event = getFactory().createEvent(arguments.targetName, arguments.eventType, arguments.properties);
		var tasks = getContext().getEventTasks(arguments.targetName, arguments.eventType);

		if (ArrayIsEmpty(tasks)) {
			if (variables.debug) {
				response.addExecutedTask(arguments.targetName, arguments.eventType);
			}
		} else {
			for (var task in tasks) {
				if (variables.debug) {
					response.addExecutedTask(arguments.targetName, arguments.eventType, task);
				}

				executeTask(task, event);
				if (event.isCanceled()) {
					break;
				}
			}
		}


		return !event.isCanceled();
	}

	package Response function getResponse() {
		return variables.response;
	}

	public array function getExecutedTasks() {
		return variables.executedTasks;
	}

	/**
	 * Executes the given task using the given event.
	 **/
	private void function executeTask(required struct task, required Event event) {

		// a task can be one of the following:
		// invoke: invoke the event handler of that name
		// render: render the view of that name
		// dispatch: dispatch the event of that name
		if (StructKeyExists(arguments.task, "invoke")) {
			// invoke the given handler method on the specified controller
			// the invoke key should be of the form <name>.<method>
			var method = ListLast(arguments.task.invoke, ".");
			var controllerName = ListDeleteAt(arguments.task.invoke, ListLen(arguments.task.invoke, "."), ".");
			var controller = getController(controllerName);
			// invoke the handler method
			controller[method](arguments.event);
			if (arguments.event.isCanceled()) {
				// if there is an instead key in the task, execute it
				if (StructKeyExists(arguments.task, "instead")) {
					executeTask(arguments.task.instead, arguments.event);
				}
			}

		} else if (StructKeyExists(arguments.task, "render")) {
			var template = arguments.task.render;
			if (arguments.task.render does not contain "/") {
				template = arguments.event.getTarget() & "/" & template;
			}

			getContext().render(template, arguments.event.getProperties(), variables.response);

		} else if (StructKeyExists(arguments.task, "dispatch")) {
			// dispatch the given event
			var eventType = arguments.task.dispatch;
			var targetName = arguments.event.getTarget();
			if (ListLen(eventType, ".") > 1) {
				targetName = ListFirst(eventType, ".");
				eventType = ListLast(eventType, ".");
			}
			var success = processEvent(targetName, eventType, arguments.event.getProperties());

			if (!success) {
				arguments.event.cancel();
				// if there is an instead key in the task, execute it
				if (StructKeyExists(arguments.task, "instead")) {
					executeTask(arguments.task.instead, arguments.event);
				}
			}

		} else {
			throw(type = "cflow", message = "Invalid definition for event #arguments.event.getTarget()#.#arguments.event.getType()#");
		}

	}

	private Controller function getController(required string name) {
		if (!StructKeyExists(variables.controllers, arguments.name)) {
			variables.controllers[arguments.name] = getFactory().createController(arguments.name, this);
		}

		return variables.controllers[arguments.name];
	}

	private Context function getContext() {
		return variables.context;
	}

	private Context function getFactory() {
		return variables.factory;
	}

}