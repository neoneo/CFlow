component Context accessors="true" {

	property name="implicitTasks" type="boolean" default="false";
	property name="defaultTarget" type="string" default="";
	property name="defaultEvent" type="string" default="";
	property name="controllerMapping" type="string" default="";
	property name="viewMapping" type="string" default="";

	variables.controllers = {}; // controllers are static, so we need only one instance of each
	variables.tasks = {
		event = {},
		start = {},
		end = {},
		before = {},
		after = {}
	};

	/**
	 * Default request handling implementation.
	 *
	 * The parameter values in the url and form scopes are collected as properties for the event.
	 * The target and event parameters are used to dispatch the corresponding event.
	 * If no target or event parameters are present, the default values for these parameters are used.
	 **/
	public Response function handleRequest() {

		var properties = StructCopy(url);
		StructAppend(properties, form, false);

		var targetName = "";
		var eventType = "";
		if (StructKeyExists(properties, "target")) {
			targetName = properties.target;
		} else {
			targetName = getDefaultTarget();
		}
		if (StructKeyExists(properties, "event")) {
			eventType = properties.event;
		} else {
			eventType = getDefaultEvent();
		}

		return handleEvent(targetName, eventType, properties);
	}

	/**
	 * Fires an event on the given target.
	 **/
	public Response function handleEvent(required string targetName, required string eventType, struct properties = {}) {

		var response = createResponse();
		var event = createEvent(arguments.targetName, arguments.eventType, arguments.properties, response);

		var success = runStartTasks(event);

		// only run the event task if we have success
		if (success) {
			success = dispatchEvent(event);
		}

		// the end tasks are always run
		if (!success) {
			// for the remainder, we need an event object with its canceled flag reset
			event = event.clone();
		}

		runEndTasks(event);

		return response;
	}

	public boolean function dispatchEvent(required Event event) {

		var success = runBeforeTasks(arguments.event);

		if (success) {
			success = runEventTasks(arguments.event);
		}

		if (success) {
			success = runAfterTasks(arguments.event);
		}

		return success;
	}

	public void function register(required Task task, required string phase, required string targetName, string eventType) {

		var phaseTask = JavaCast("null", 0);

		switch (arguments.phase) {
			case "start":
			case "end":
			case "before":
			case "after":
				if (!StructKeyExists(variables.tasks[arguments.phase], arguments.targetName)) {
					variables.tasks[arguments.phase][arguments.targetName] = createPhaseTask();
				}
				phaseTask = variables.tasks[arguments.phase][arguments.targetName];
				break;

			case "event":
				if (!StructKeyExists(arguments, "eventType")) {
					throw(type = "cflow", message = "Event type is required when registering tasks for the event phase");
				}
				if (!StructKeyExists(variables.tasks.event, arguments.targetName)) {
					variables.tasks.event[arguments.targetName] = {};
				}
				if (!StructKeyExists(variables.tasks.event[arguments.targetName], arguments.eventType)) {
					variables.tasks.event[arguments.targetName][arguments.eventType] = createPhaseTask();
				}
				phaseTask = variables.tasks.event[arguments.targetName][arguments.eventType];
				break;

			default:
				throw(type = "cflow", message = "Unknown phase '#arguments.phase#'");
				break;
		}

		phaseTask.addSubtask(arguments.task);

	}

	// TEMPLATE METHODS ===========================================================================

	private boolean function runStartTasks(required Event event) {
		return getPhaseTask("start", arguments.event.getTarget()).run(arguments.event);
	}

	private boolean function runBeforeTasks(required Event event) {
		return getPhaseTask("before", arguments.event.getTarget()).run(arguments.event);
	}

	private boolean function runAfterTasks(required Event event) {
		return getPhaseTask("after", arguments.event.getTarget()).run(arguments.event);
	}

	private boolean function runEndTasks(required Event event) {
		return getPhaseTask("end", arguments.event.getTarget()).run(arguments.event);
	}

	private boolean function runEventTasks(required Event event) {

		var task = JavaCast("null", 0);
		// check if there are tasks for this event
		var targetName = arguments.event.getTarget();
		var eventType = arguments.event.getType();
		if (StructKeyExists(variables.tasks.event, targetName) && StructKeyExists(variables.tasks.event[targetName], eventType)) {
			task = variables.tasks.event[targetName][eventType];
		} else {
			task = createPhaseTask();
			if (getImplicitTasks()) {
				// we now assume there is a controller with the name of the target, that exposes a method with the name of the event type
				task.addSubtask(createInvokeTask(targetName, eventType));
				// and that there is a template in a directory with the name of the target, that has the same name as the event type
				task.addSubtask(createRenderTask(targetName & "/" & eventType));
				// add this task to the cache, so that next time we can reuse it
				variables.tasks.event[targetName][eventType] = task;
			}
		}

		return task.run(arguments.event);
	}

	/**
	 * Returns the task for the given phase and event.
	 **/
	private Task function getPhaseTask(required string phase, required string targetName) {

		if (!StructKeyExists(variables.tasks[arguments.phase], arguments.targetName)) {
			variables.tasks[arguments.phase][arguments.targetName] = createPhaseTask();
		}

		return variables.tasks[arguments.phase][arguments.targetName];
	}

	private Controller function getController(required string name) {

		if (!StructKeyExists(variables.controllers, arguments.name)) {
			var controllerName = arguments.name;
			if (Len(getControllerMapping()) > 0) {
				controllerName = getControllerMapping() & "." & controllerName;
			}
			variables.controllers[arguments.name] = new "#controllerName#"(this);
		}

		return variables.controllers[arguments.name];
	}

	// FACTORY METHODS ============================================================================

	public Task function createInvokeTask(required string controllerName, required string methodName) {
		return new InvokeTask(getController(arguments.controllerName), arguments.methodName);
	}

	public Task function createDispatchTask(required string targetName, required string eventType, boolean cancelFailed = true) {
		return new DispatchTask(this, arguments.targetName, arguments.eventType, arguments.cancelFailed);
	}

	public Task function createRenderTask(required string template) {

		var templateLocation = arguments.template;
		if (Len(getViewMapping()) > 0) {
			templateLocation = getViewMapping() & "/" & arguments.template;
		}

		return new RenderTask(templateLocation);
	}

	private Task function createPhaseTask() {
		return new PhaseTask();
	}

	package Event function createEvent(required string targetName, required string eventType, required struct properties, required Response response) {
		return new Event(arguments.targetName, arguments.eventType, arguments.properties, arguments.response);
	}

	private Response function createResponse() {
		return new Response();
	}

}