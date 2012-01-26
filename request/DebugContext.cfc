component DebugContext extends="Context" {

	// FACTORY METHODS ============================================================================

	public Task function createInvokeTask(required string controllerName, required string methodName) {

		var task = super.createInvokeTask(argumentCollection = arguments);

		return new DebugTask(task, arguments);
	}

	public Task function createDispatchTask(required string targetName, required string eventType, boolean cancelFailed = true) {

		var task = super.createDispatchTask(argumentCollection = arguments);
		//var task = new DispatchTask(this, arguments.targetName, arguments.eventType, arguments.cancelFailed);

		return new DebugTask(task, arguments);
	}

	public Task function createRenderTask(required string template) {

		var task = super.createRenderTask(argumentCollection = arguments);

		return new DebugTask(task, arguments);
	}

	package Event function createEvent(required string targetName, required string eventType, required struct properties, required Response response) {
		return new DebugEvent(arguments.targetName, arguments.eventType, arguments.properties, arguments.response);
	}

	// TEMPLATE METHODS ===========================================================================

	private boolean function runStartTasks(required Event event) {

		arguments.event.record("startTasks");

		try {
			var success = super.runStartTasks(arguments.event);
		} catch (any e) {
			handleException(e, arguments.event);
		}

		arguments.event.record("startTasks");

		return success;
	}

	private boolean function runBeforeTasks(required Event event) {

		arguments.event.record("beforeTasks");

		try {
			var success = super.runBeforeTasks(arguments.event);
		} catch (any e) {
			handleException(e, arguments.event);
		}

		arguments.event.record("beforeTasks");

		return success;
	}

	private boolean function runAfterTasks(required Event event) {

		arguments.event.record("afterTasks");

		try {
			var success = super.runAfterTasks(arguments.event);
		} catch (any e) {
			handleException(e, arguments.event);
		}

		arguments.event.record("afterTasks");

		return success;
	}

	private boolean function runEndTasks(required Event event) {

		arguments.event.record("endTasks");

		try {
			var success = super.runEndTasks(arguments.event);
		} catch (any e) {
			handleException(e, arguments.event);
		}

		arguments.event.record("endTasks");

		// render debug output
		renderDebugOutput(arguments.event);

		return success;
	}

	private boolean function runEventTasks(required Event event) {

		arguments.event.record("eventTasks");

		try {
			var success = super.runEventTasks(arguments.event);
		} catch (any e) {
			handleException(e, arguments.event);
		}

		arguments.event.record("eventTasks");

		return success;
	}

	private void function renderDebugOutput(required Event event) {

		lock name="renderDebugOutput" timeout="1" {
			var viewMapping = getViewMapping();
			setViewMapping("/cflow/request");
			// create a (non-debug) render task and run it
			var task = super.createRenderTask("debugoutput");
			setViewMapping(viewMapping);
		}
		task.run(arguments.event);

	}

	private void function handleException(required any exception, required Event event) {

		arguments.event.record("exception", {exception: exception});
		var response = arguments.event.getResponse();
		response.clear();
		renderDebugOutput(arguments.event);
		response.render();
		abort;

	}

}