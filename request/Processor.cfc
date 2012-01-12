component Processor {

	public void function init(required Context context) {
		variables.context = arguments.context;
		variables.response = createResponse();

		variables.debug = getContext().getDebug();
	}

	/**
	 * Processes the tasks using the event.
	 **/
	public boolean function processEvent(required string targetName, required string eventType, struct properties = {}) {

		var event = createEvent(arguments.targetName, arguments.eventType, arguments.properties);
		var tasks = getContext().getEventTasks(arguments.targetName, arguments.eventType);

<<<<<<< HEAD
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
=======
		return processTasks(tasks, event);
	}

	package Response function getResponse() {
		return variables.response;
	}

	private boolean function processTasks(required array tasks, required Event event) {

		if (ArrayIsEmpty(arguments.tasks)) {
			if (variables.debug) {
				response.addProcessedTask(arguments.event.getTarget(), arguments.event.getType());
>>>>>>> Refactoring
			}
		} else {
			for (var task in arguments.tasks) {
				if (variables.debug) {
<<<<<<< HEAD
					response.addExecutedTask(arguments.event.getTarget(), arguments.event.getType(), task);
				}

				processTask(task, arguments.event);
				if (arguments.event.isCanceled()) {
=======
					response.addProcessedTask(arguments.event.getTarget(), arguments.event.getType(), task);
				}

				processTask(task, event);
				if (event.isCanceled()) {
>>>>>>> Refactoring
					break;
				}
			}
		}
<<<<<<< HEAD
		
=======

		return !event.isCanceled();
>>>>>>> Refactoring
	}

	/**
	 * Processes the given task using the given event.
	 **/
	private void function processTask(required struct task, required Event event) {

		// a task can be one of the following:
		// invoke: invoke the event handler of that name
		// render: render the view of that name
		// dispatch: dispatch the event of that name
		switch (arguments.task.type) {
			case "invoke":
				// invoke the given handler method on the specified controller
<<<<<<< HEAD
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
=======
				getContext().getController(arguments.task.controller)[arguments.task.method](arguments.event);
				break;

			case "render":
				getContext().render(arguments.task.template, arguments.event.getProperties(), variables.response);
				break;

			case "dispatch":
				// dispatch the given event
				var success = processEvent(arguments.task.target, arguments.task.event, arguments.event.getProperties());

				if (!success) {
					arguments.event.cancel();
				}
				break;

			default:
				throw(type = "cflow", message = "Invalid task for event #arguments.event.getType()# on target #arguments.event.getTarget()#");
>>>>>>> Refactoring
				break;
		}

		if (arguments.event.isCanceled()) {
			// if there is an instead key in the task, execute the tasks in it
			if (StructKeyExists(arguments.task, "instead")) {
				// the event is canceled, so for the next tasks we need a new event object
				processTasks(arguments.task.instead, getContext().createEvent(arguments.event.getTarget(), arguments.event.getType(), arguments.event.getProperties()));
			}
		}

	}

	private Context function getContext() {
		return variables.context;
	}

	private Event function createEvent(required string targetName, required string eventType, struct properties = {}) {
		return new Event(this, arguments.targetName, arguments.eventType, arguments.properties);
	}

	private Response function createResponse() {
		return new Response();
	}

}