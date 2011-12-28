component Context {

	property name="debug" type="boolean" default="false" getter="true" setter="true";
	property name="implicitEvents" type="boolean" default="false" getter="true" setter="true";
	property name="defaultTarget" type="string" default="" getter="true" setter="true";
	property name="defaultEvent" type="string" default="" getter="true" setter="true";
	property name="controllerMapping" type="string" default="" getter="true" setter="true";
	property name="viewMapping" type="string" default="" getter="true" setter="true";
	property name="configurationPath" type="string" default="" getter="true" setter="true";

	property name="renderer" type="Renderer" getter="true" setter="true";

	public void function init() {

		variables.controllers = {}; // controllers are static, so we need only one instance of each
		variables.tasks = {};

	}

	/**
	 * Default request handling implementation.
	 *
	 * The parameter values in the url and form scopes are collected as properties for the event.
	 * The target and event parameters are used to fire the corresponding event.
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

		var processor = createProcessor();

		// TODO: execute start tasks

		processor.processEvent(arguments.targetName, arguments.eventType, arguments.properties);

		// TODO: execute end tasks

		return processor.getResponse();
	}

	public boolean function register(required string name, required string targetName, required string eventType, string phase = "") {

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
			if (getImplicitEvents()) {
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

	public void function render(required string template, required struct properties, required Response response) {

		var renderer = getRenderer();
		if (!StructKeyExists(local, "renderer")) {
			renderer = new View();
			setRenderer(renderer);
		}

		renderer.render(getViewMapping() & "/" & arguments.template, arguments.properties, arguments.response);
	}


	// GETTERS AND SETTERS FOR SETTINGS ===========================================================
/*
	public void function setControllerMapping(required string mapping) {
		variables.controllerMapping = arguments.mapping;
	}

	public void function setViewMapping(required string mapping) {
		variables.viewMapping = arguments.mapping;
	}

	public void function setDefaultTarget(required string targetName) {
		variables.defaultTarget = arguments.targetName;
	}

	public void function setDefaultEvent(required string eventType) {
		variables.defaultEvent = arguments.eventType;
	}

	public void function setImplicitEvents(required boolean set) {
		variables.implicitEvents = set;
	}

	public void function setDebug(required boolean set) {
		variables.debug = set;
	}

	public void function getControllerMapping() {
		return variables.controllerMapping;
	}

	public void function getViewMapping() {
		return variables.viewMapping;
	}

	public void function getDefaultTarget() {
		return variables.defaultTarget;
	}

	public void function getDefaultEvent() {
		return variables.defaultEvent;
	}

	public void function setImplicitEvents(required boolean set) {
		variables.implicitEvents = set;
	}

	public void function setDebug(required boolean set) {
		variables.debug = set;
	}
	* */

	// FACTORY METHODS ============================================================================

	public Controller function getController(required string name, required Processor processor) {

		var controller = JavaCast("null", 0);
		if (StructKeyExists(variables.controllers, arguments.name)) {
			controller = variables.controllers[arguments.name];
		} else {
			controller = new "#getControllerMapping()#.#arguments.name#"(arguments.processor);
		}

		return controller;
	}

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