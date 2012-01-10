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

		processTasks(tasks, event);

		return !event.isCanceled();
	}
	
	/**
	 * Returns the tasks that were executed by this processor. This is only useful if the associated context is in debug mode.
	 **/
	public array function getExecutedTasks() {
		return variables.executedTasks;
	}

	/**
	 * Returns the response object.
	 **/
	package Response function getResponse() {
		return variables.response;
	}
	
	private void processTasks(required array tasks, required Event event) {

		if (ArrayIsEmpty(arguments.tasks)) {
			if (variables.debug) {
				response.addExecutedTask(arguments.event.getTarget(), arguments.event.getType());
			}
		} else {
			for (var task in arguments.tasks) {
				if (variables.debug) {
					response.addExecutedTask(arguments.event.getTarget(), arguments.event.getType(), task);
				}

				processTask(task, arguments.event);
				if (arguments.event.isCanceled()) {
					break;
				}
			}
		}
		
	}

	/**
	 * Executes the given task using the given event.
	 **/
	private void function processTask(required struct task, required Event event) {

		// a task can be one of the following:
		// invoke: invoke the event handler of that name
		// render: render the view of that name
		// dispatch: dispatch the event of that name
		switch (arguments.task.type) {
			case "invoke":
				// invoke the given handler method on the specified controller
				var controller = getController(arguments.task.controller);
				// invoke the handler method
				controller[arguments.task.method](arguments.event);
				if (arguments.event.isCanceled()) {
					// if there are instead tasks, execute them
					if (StructKeyExists(arguments.task, "instead")) {
						processTasks(arguments.task.instead, arguments.event.clone());
					}
				}
				break;
			
			case "render":
				var template = arguments.task.template;
				if (template does not contain "/") {
					template = arguments.event.getTarget() & "/" & template;
				}
	
				getContext().render(template, arguments.event.getProperties(), variables.response);
				break;

			case "dispatch":
				// dispatch the given event
				var success = processEvent(arguments.task.target, arguments.task.event, arguments.event.getProperties());
	
				if (!success) {
					arguments.event.cancel();
					if (StructKeyExists(arguments.task, "instead")) {
						processTasks(arguments.task.instead, arguments.event.clone());
					}
				}
				break;
			
			default:
				throw(type = "cflow", message = "Invalid definition for event #arguments.event.getTarget()#.#arguments.event.getType()#");
				break;
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