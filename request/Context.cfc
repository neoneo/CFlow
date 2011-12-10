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
	public struct function handleRequest(required string defaultTargetName, required string defaultEventType) {
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

		return fireEvent(targetName, eventType, properties);
	}

	/**
	 * Fires an event on the given target.
	 **/
	public struct function fireEvent(required string targetName, required string eventType, struct properties = {}) {

		var processor = variables.factory.createProcessor();
		var controller = variables.factory.createController(arguments.targetName);
		var event = variables.factory.createEvent(controller, arguments.eventType, arguments.properties);

		// TODO: execute start tasks

		var tasks = getEventTasks(arguments.targetName, arguments.eventType);
		processor.processTasks(tasks, event);

		// TODO: execute end tasks

		return processor.getResponse();
	}

	public boolean function register(required string name, required string targetName, required string eventType, string phase = "") {

	}

	public Factory function getFactory() {
		return variables.factory;
	}

	// PRIVATE METHODS ----------------------------------------------------------------------------

	/**
	 * Returns an array of tasks to be executed for the given target and event.
	 **/
	private array function getEventTasks(required string targetName, required string eventType) {

		var tasks = JavaCast("null", 0);
		// check if the controller is registered and if it is listening to the event
		if (StructKeyExists(variables.controllers, arguments.targetName) && StructKeyExists(variables.controllers[arguments.targetName], arguments.eventType)) {
			tasks = variables.controllers[arguments.targetName][arguments.eventType];
		}

		if (IsNull(tasks)) {
			if (variables.settings.implicitEvents) {
				// use the event type as listener and view name
				tasks = [
					{"invoke" = arguments.eventType},
					{"view" = arguments.eventType}
				];
			}
		}

		return tasks;
	}
}