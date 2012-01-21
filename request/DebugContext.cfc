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

		ArrayAppend(arguments.event.debugInformation, {
			"message" = "dispatchEvent",
			"target" = arguments.event.getTarget(),
			"event" = arguments.event.getType(),
			"tickcount" = GetTickCount()
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

	package Event function createEvent(required string targetName, required string eventType, required struct data, Response response) {

		var event = super.createEvent(argumentCollection = arguments);

		if (!StructKeyExists(event, "debugInformation")) {
			event.debugInformation = [];
		}

		return event;
	}

}