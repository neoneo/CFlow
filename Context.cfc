/*
   Copyright 2012 Neo Neo

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

component Context accessors="true" {

	property name="implicitTasks" type="boolean" default="false";
	property name="controllerMapping" type="string" default="";
	property name="viewMapping" type="string" default="";
	property name="endPoint" type="EndPoint";

	// target and event to dispatch if no target or event is specified
	property name="defaultTarget" type="string" default="";
	property name="defaultEvent" type="string" default="";
	// target and event to dispatch if an unknown event is handled
	property name="undefinedTarget" type="string" default="";
	property name="undefinedEvent" type="string" default="";

	variables.controllers = {}; // controllers are static, so we need only one instance of each
	variables.targets = {}; // tasks for targets and events
	variables.accessLevels = {
		private = 0,
		public = 1
	};

	// just create an instance of the default request strategy
	// if it is not needed, it will be garbage collected
	// assuming this will only occur once in the life of the application, it's not a big cost
	variables.endPoint = new DefaultEndPoint();

	/**
	 * Extracts the request parameters using the request strategy and starts the event handling cycle.
	 **/
	public Response function handleRequest() {

		var parameters = getEndPoint().collectParameters();

		// if no target or event is given, revert to the default target and/ or event
		var targetName = StructKeyExists(parameters, "target") ? parameters.target : variables.defaultTarget;
		var eventType = StructKeyExists(parameters, "event") ? parameters.event : variables.defaultEvent;

		return handleEvent(targetName, eventType, parameters);
	}

	/**
	 * Runs the event handling cycle.
	 **/
	public Response function handleEvent(required string targetName, required string eventType, struct parameters = {}) {

		var event = createEvent(arguments.targetName, arguments.eventType, arguments.parameters);

		if (!targetExists(targetName) || !eventExists(targetName, eventType, variables.accessLevels.public)) {
			event.setTarget(getUndefinedTarget());
			event.setType(getUndefinedEvent());
		}

		runTasks(event);

		return event.getResponse();
	}

	/**
	 * Runs the tasks associated with the event.
	 **/
	public boolean function dispatchEvent(required Event event, required string targetName, required string eventType) {

		local.targetName = arguments.event.getTarget();
		local.eventType = arguments.event.getType();
		arguments.event.setTarget(arguments.targetName);
		arguments.event.setType(arguments.eventType);
		arguments.event.target = arguments.targetName;
		arguments.event.event = arguments.eventType;

		success = runEventTasks(arguments.event, arguments.targetName, arguments.eventType);

		arguments.event.setTarget(local.targetName);
		arguments.event.setType(local.eventType);
		arguments.event.target = local.targetName;
		arguments.event.event = local.eventType;

		return success;
	}

	// TEMPLATE METHODS ===========================================================================

	/**
	 * Runs the start, end and event tasks.
	 **/
	private void function runTasks(required Event event) {

		var targetName = arguments.event.getTarget();
		var eventType = arguments.event.getType();

		// check if the event is defined
		if (!eventExists(targetName, eventType)) {
			if (getImplicitTasks()) {
				// create a task according to the conventions
				var task = createPhaseTask();
				// if there is a controller with the name of the target, create an invoke task that invokes the handler by the name of the event type
				var controllerName = getComponentName(targetName, getControllerMapping());
				if (componentExists(controllerName)) {
					task.addSubtask(createInvokeTask(targetName, eventType));
				}
				// always create a render task that renders a view in a directory with the name of the target, that has the same name as the event type
				task.addSubtask(createRenderTask(targetName & "/" & eventType));
				// register this task, so that next time it is picked up immediately
				if (!targetExists(targetName)) {
					registerTarget(targetName);
				}
				registerEvent(targetName, eventType);
				registerEventTask(task, targetName, eventType);
			} else {
				// if there is an undefined event, and it is not the current event, run its tasks
				if (Len(variables.undefinedTarget) > 0 && Len(variables.undefinedEvent) > 0 && (targetName != variables.undefinedTarget || eventType != variables.undefinedEvent)) {
					targetName = variables.undefinedTarget;
					eventType = variables.undefinedEvent;
					// overwrite the event target and type
					arguments.event.setTarget(targetName);
					arguments.event.setType(eventType);
				}
			}
		}

		var success = runStartTasks(arguments.event);
		// only run the event tasks if we have success
		if (success) {
			success = dispatchEvent(arguments.event, targetName, eventType);
		}
		// the end tasks are always run, unless the event is aborted
		if (!arguments.event.isAborted()) {
			if (!success) {
				// for the remainder, we need an event object with its canceled flag reverted
				arguments.event.revert();
			}

			runEndTasks(arguments.event);
		}

	}

	private boolean function runStartTasks(required Event event) {
		return getStartTask(arguments.event.getTarget()).run(arguments.event);
	}

	private boolean function runEndTasks(required Event event) {
		return getEndTask(arguments.event.getTarget()).run(arguments.event);
	}

	private boolean function runEventTasks(required Event event) {
		return getEventTask(arguments.event.getTarget(), arguments.event.getType()).run(arguments.event);
	}

	/**
	 * Returns the task for the start phase.
	 **/
	private Task function getStartTask(required string targetName) {
		var target = getTarget(arguments.targetName);
		if (!StructKeyExists(target, "start")) {
			target.start = createPhaseTask();
		}
		return target.start;
	}

	/**
	 * Returns the task for the end phase.
	 **/
	private Task function getEndTask(required string targetName) {
		var target = getTarget(arguments.targetName);
		if (!StructKeyExists(target, "end")) {
			target.end = createPhaseTask();
		}
		return target.end;
	}

	/**
	 * Returns the task for the event.
	 **/
	private Task function getEventTask(required string targetName, required string eventType) {
		var event = getEvent(arguments.targetName, arguments.eventType);
		if (!StructKeyExists(event, "task")) {
			event.task = createPhaseTask();
		}
		return event.task;
	}

	/**
	 * Returns the controller with the given name.
	 **/
	private component function getController(required string name) {

		if (!StructKeyExists(variables.controllers, arguments.name)) {
			variables.controllers[arguments.name] = createController(arguments.name);
		}

		return variables.controllers[arguments.name];
	}

	private component function createController(required string name) {

		var controllerName = getComponentName(arguments.name, getControllerMapping());
		if (!componentExists(controllerName)) {
			Throw(type = "cflow", message = "Controller #controllerName# does not exist");
		}

		return new "#controllerName#"();
	}

	/**
	 * Returns true if the component with the given name can be instantiated.
	 **/
	private boolean function componentExists(required string fullName) {

		var componentPath = ExpandPath("/" & ListChangeDelims(arguments.fullName, "/", ".") & ".cfc");

		return FileExists(componentPath);
	}

	private string function getComponentName(required string name, string mapping = "") {

		// let arguments.name accept slashes as well as dots for delimiters
		var componentName = ListChangeDelims(arguments.name, ".", "/");
		if (Len(arguments.mapping) > 0) {
			componentName = ListChangeDelims(arguments.mapping, ".", "/") & "." & componentName;
		}

		return componentName;
	}

	public void function registerTarget(required string targetName) {
		if (targetExists(arguments.targetName)) {
			Throw("Target '#arguments.targetName#' already exists", "cflow");
		}
		variables.targets[arguments.targetName] = {
			events = {}
		};
	}

	public boolean function targetExists(required string name) {
		return StructKeyExists(variables.targets, arguments.name);
	}

	private struct function getTarget(required string name) {
		if (!targetExists(arguments.name)) {
			Throw("Target '#arguments.name#' does not exist", "cflow");
		}
		return variables.targets[arguments.name];
	}

	public void function registerEvent(required string targetName, required string eventType, string access = "public") {
		if (eventExists(arguments.targetName, arguments.eventType)) {
			Throw("Event '#arguments.eventType#' already exists for target '#arguments.targetName#'", "cflow");
		}
		getTarget(arguments.targetName).events[arguments.eventType] = {
			accessLevel = variables.accessLevels[arguments.access]
		};
	}

	public boolean function eventExists(required string targetName, required string type, numeric accessLevel = variables.accessLevels.private) {
		var events = getTarget(arguments.targetName).events;
		return StructKeyExists(events, arguments.type) && events[arguments.type].accessLevel >= arguments.accessLevel;
	}

	private struct function getEvent(required string targetName, required string type) {
		var events = getTarget(arguments.targetName).events;
		if (!StructKeyExists(events, arguments.type)) {
			Throw("Event '#arguments.type#' does not exist for target '#arguments.targetName#'", "cflow");
		}
		return events[arguments.type];
	}

	public void function registerStartTask(required Task task, required string targetName) {
		getStartTask(arguments.targetName).addSubtask(arguments.task);
	}

	public void function registerEndTask(required Task task, required string targetName) {
		getEndTask(arguments.targetName).addSubtask(arguments.task);
	}

	public void function registerEventTask(required Task task, required string targetName, required string eventType) {
		getEventTask(arguments.targetName, arguments.eventType).addSubtask(arguments.task);
	}

	// FACTORY METHODS ============================================================================

	public InvokeTask function createInvokeTask(required string controllerName, required string handlerName) {
		return new InvokeTask(getController(arguments.controllerName), arguments.handlerName);
	}

	public DispatchTask function createDispatchTask(required string targetName, required string eventType) {
		return new DispatchTask(this, arguments.targetName, arguments.eventType);
	}

	public RenderTask function createRenderTask(required string view, string key = "") {
		return new RenderTask(arguments.view, getViewMapping(), arguments.key, getEndPoint());
	}

	public RedirectTask function createRedirectTask(string location = "", string target = "", string event = "", struct parameters = {}, boolean permanent = false) {
		return new RedirectTask(arguments.location, arguments.target, arguments.event, arguments.parameters, arguments.permanent, getEndPoint());
	}

	public ThreadTask function createThreadTask(string action = "run", string name = "", string priority = "normal", numeric timeout = 0, numeric duration = 0) {
		return new ThreadTask(this, arguments.action, arguments.name, arguments.priority, arguments.timeout);
	}

	public IfTask function createIfTask(required string condition) {
		return new IfTask(arguments.condition);
	}

	public ElseTask function createElseTask(string condition = "") {
		return new ElseTask(arguments.condition);
	}

	public SetTask function createSetTask(required string name, required string expression, boolean overwrite = true) {
		return new SetTask(arguments.name, arguments.expression, arguments.overwrite);
	}

	public PhaseTask function createPhaseTask() {
		return new PhaseTask();
	}

	public AbortTask function createAbortTask() {
		return new AbortTask();
	}

	public CancelTask function createCancelTask() {
		return new CancelTask();
	}

	public Event function createEvent(required string target, required string type, struct parameters = {}) {
		return new Event(this, createResponse(), arguments.target, arguments.type, arguments.parameters);
	}

	public Response function createResponse() {
		return new Response();
	}

}