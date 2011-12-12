component {

	public void function init() {
		variables.controllers = {

		};

		variables.settings = {
			implicitEvents = false
		};

		variables.factory = new Factory(this);
	}

	/**
	 * Default request handling implementation.
	 *
	 * It collects the parameter values in the url and form scopes as properties for the event.
	 * The target and event parameters are used to fire the corresponding event.
	 * If no target or event parameters are present, the default values for these parameters, passed in as arguments, are used.
	 **/
	public Response function handleRequest(required string defaultTargetName, required string defaultEventType) {
		var properties = StructCopy(url);
		StructAppend(properties, form, false);

		var targetName = arguments.defaultTargetName;
		if (StructKeyExists(properties, "target")) {
			targetName = properties.target;
		}
		var eventType = arguments.defaultEventType;
		if (StructKeyExists(properties, "event")) {
			eventType = properties.event;
		}

		return handleEvent(targetName, eventType, properties);
	}

	/**
	 * Fires an event on the given target.
	 **/
	public Response function handleEvent(required string targetName, required string eventType, struct properties = {}) {

		var processor = getFactory().createProcessor();

		// TODO: execute start tasks

		processor.processEvent(arguments.targetName, arguments.eventType, arguments.properties);

		// TODO: execute end tasks

		return processor.getResponse();
	}

	public boolean function register(required string name, required string targetName, required string eventType, string phase = "") {

	}

	public Factory function getFactory() {
		return variables.factory;
	}

	/**
	 * Returns an array of tasks to be executed for the given target and event.
	 **/
	public array function getEventTasks(required string targetName, required string eventType) {

		var tasks = JavaCast("null", 0);
		// check if the controller is registered and if it is listening to the event
		if (StructKeyExists(variables.controllers, arguments.targetName) && StructKeyExists(variables.controllers[arguments.targetName], arguments.eventType)) {
			tasks = variables.controllers[arguments.targetName][arguments.eventType];
		}

		if (!StructKeyExists(local, "tasks")) {
			if (variables.settings.implicitEvents) {
				// use the event type as listener and view name
				tasks = [
					{"invoke" = arguments.eventType},
					{"render" = arguments.eventType}
				];
			} else {
				tasks = [];
			}
		}

		return tasks;
	}

	// FACTORY METHODS ============================================================================

	public Controller function createController(required string name, required Processor processor) {
		return new "#arguments.name#"(arguments.processor);
	}

	public View function createView(required string name) {
		return new "#arguments.name#"();
	}

	public Event function createEvent(required string targetName, required string eventType, struct properties = {}) {
		return new Event(arguments.target, arguments.eventType, arguments.properties);
	}

	public Processor function createProcessor() {
		return new Processor(this);
	}

}