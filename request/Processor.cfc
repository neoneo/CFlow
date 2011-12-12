component {

	variables.controllers = {};

	public void function init(required Context context) {
		variables.context = arguments.context;
		variables.factory = variables.context; //.getFactory();
		variables.response = variables.factory.createResponse();
	}

	/**
	 * Processes the tasks using the event.
	 **/
	public boolean function processEvent(required string targetName, required string eventType, struct properties = {}) {

		var event = getFactory().createEvent(arguments.targetName, arguments.eventType, arguments.properties);
		var tasks = getContext().getEventTasks(arguments.targetName, arguments.eventType);
		for (var task in arguments.tasks) {
			executeTask(task, arguments.event);
			if (arguments.event.isCanceled()) {
				break;
			}
		}

		return !arguments.event.isCanceled();
	}

	public Response function getResponse() {
		return variables.response;
	}

	/**
	 * Executes the given task using the given event.
	 **/
	private void function executeTask(required struct task, required Event event) {

		// a task can be one of the following:
		// invoke: invoke the event handler of that name
		// render: render the view of that name
		// dispatch: dispatch the event of that name
		if (StructKeyExists(arguments.task, "invoke") {
			// invoke the given event handler
			var controller = JavaCast("null", 0);
			var method = "";
			if (ListLen(arguments.task.invoke, ".") == 1) {
				// no explicit handler specified, so use the event target
				controller = getController(arguments.event.getTarget());
				method = arguments.task.invoke;
			} else {
				controller = getController(ListFirst(arguments.task.invoke, "."));
				method = ListLast(arguments.task.invoke);
			}
			// invoke the handler method
			controller[method](arguments.event);
			if (arguments.event.isCancelled()) {
				// if there is an instead key in the task, execute it
				if (StructKeyExists(arguments.task, "instead") {
					executeTask(arguments.task.instead, arguments.event);
				}
			}

		} else if (StructKeyExists(arguments.task, "render")) {
			var viewName = arguments.task.view;
			if (ListLen(arguments.task.view, ".") == 1) {
				viewName = arguments.event.getTarget() & "." & viewName;
			}

			var result = getFactory().createView(viewName, this).render(arguments.event.getProperties());
			// gather the result in the response instance
			getResponse().write(viewName, result);

		} else if (StructKeyExists(arguments.task, "dispatch") {
			// dispatch the given event
			var eventType = arguments.task.dispatch;
			var targetName = arguments.event.getTarget();
			if (ListLen(eventType) > 1) {
				targetName = ListFirst(eventType, ".");
				eventType = ListLast(eventType, ".");
			}
			var success = processEvent(targetName, eventType, arguments.event.getProperties());

			if (!success) {
				arguments.event.cancel();
				// if there is an instead key in the task, execute it
				if (StructKeyExists(arguments.task, "instead") {
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

	private Factory getFactory() {
		return variables.factory;
	}

}