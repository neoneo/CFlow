component Context {

	public void function init() {
		variables.tasks = {
			"world" = {
				"hello" = [
					/*{
						"invoke" = "World.voerUit",
						"instead" = {
							"dispatch" = "nietgelukt"
						}
					},*/
					{"invoke" = "Reader.readFile"},
					{"render" = "reader/dumpFile"},
					{"render" = "laatzien"}
				],
				"nietgelukt" = [
					{"invoke" = "World.naKijken"},
					{"dispatch" = "niemandluistert"},
					{"dispatch" = "universe.bye"}
				]
			},
			"universe" = {
				"bye" = [
					{"render" = "totziens"}
				]
			}
		};

		variables.settings = {
			debug = true,
			implicitEvents = false,
			defaultTarget = "world",
			defaultEvent = "hello",
			controllerMapping = "speeltuin.cflow.controllers",
			viewMapping = "/speeltuin/cflow/views"
		};

		variables.factory = this;//new Factory(this);
		variables.view = new View();
	}

	/**
	 * Default request handling implementation.
	 *
	 * It collects the parameter values in the url and form scopes as properties for the event.
	 * The target and event parameters are used to fire the corresponding event.
	 * If no target or event parameters are present, the default values for these parameters, passed in as arguments, are used.
	 **/
	public Response function handleRequest() {
		var properties = StructCopy(url);
		StructAppend(properties, form, false);

		var targetName = variables.settings.defaultTarget;
		var eventType = variables.settings.defaultEvent;
		if (StructKeyExists(properties, "target")) {
			targetName = properties.target;
		}
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

	public Context function getFactory() {
		return variables.factory;
	}

	/**
	 * Returns an array of tasks to be executed for the given target and event.
	 **/
	public array function getEventTasks(required string targetName, required string eventType) {

		var tasks = JavaCast("null", 0);
		// check if there are tasks for this event
		if (StructKeyExists(variables.tasks, arguments.targetName) && StructKeyExists(variables.tasks[arguments.targetName], arguments.eventType)) {
			tasks = variables.tasks[arguments.targetName][arguments.eventType];
		}

		if (!StructKeyExists(local, "tasks")) {
			if (variables.settings.implicitEvents) {
				// use the event type as listener and view name
				tasks = [
					{"invoke" = arguments.targetName & "." & arguments.eventType},
					{"render" = arguments.targetName & "." & arguments.eventType}
				];
			} else {
				tasks = [];
			}
		}

		return tasks;
	}

	public View function getView() {
		return variables.view;
	}

	public void function render(required string template, required struct properties, required Response response) {
		getView().render(variables.settings.viewMapping & "/" & arguments.template, arguments.properties, arguments.response);
	}

	package string function getSetting(required string key) {
		return variables.settings[arguments.key];
	}

	// FACTORY METHODS ============================================================================

	public Controller function createController(required string name, required Processor processor) {
		return new "#variables.settings.controllerMapping#.#arguments.name#"(arguments.processor);
	}

	/*public View function createView(required string name, required Processor processor) {
		return new "#variables.settings.viewMapping#.#arguments.name#"();
	}*/

	public Event function createEvent(required string targetName, required string eventType, struct properties = {}) {
		return new Event(arguments.targetName, arguments.eventType, arguments.properties);
	}

	public Processor function createProcessor() {
		return new Processor(this);
	}

	public Response function createResponse() {
		return new Response();
	}

}