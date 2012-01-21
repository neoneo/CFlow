component DebugContext extends="Context" {

	variables.debugTargets = [];

	public Response function handleEvent(required string targetName, required string eventType, struct properties = {}) {

		if (!ArrayContains(variables.debugTargets, arguments.targetName)) {
			// register a render debugoutput task
			var viewMapping = getViewMapping();
			setViewMapping("/cflow/request");
			register(super.createRenderTask("debugoutput"), "end", arguments.targetName);
			setViewMapping(viewMapping);
			ArrayAppend(variables.debugTargets, arguments.targetName);
		}

		return super.handleEvent(argumentCollection = arguments);
	}

	public boolean function dispatchEvent(required Event event) {

		arguments.event.logMessage("dispatchEvent", {
			"target" = arguments.event.getTarget(),
			"event" = arguments.event.getType()
		});

		return super.dispatchEvent(arguments.event);
	}

	public Task function createInvokeTask(required string controllerName, required string methodName) {

		var task = super.createInvokeTask(argumentCollection = arguments);

		return new DebugTask(task, arguments);
	}

	public Task function createDispatchTask(required string targetName, required string eventType) {

		var task = super.createDispatchTask(argumentCollection = arguments);

		return new DebugTask(task, arguments);
	}

	public Task function createRenderTask(required string template) {

		var task = super.createRenderTask(argumentCollection = arguments);

		return new DebugTask(task, arguments);
	}

	private Task function createEventTask() {
		var task = super.createEventTask();

		return new DebugTask(task, arguments);
	}

	public Event function createEvent(required string targetName, required string eventType, required struct properties, required Response response) {
		return new DebugEvent(arguments.targetName, arguments.eventType, arguments.properties, arguments.response);
	}

}