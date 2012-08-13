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
	property name="requestStrategy" type="RequestStrategy";

	// target and event to dispatch if no target or event is specified
	property name="defaultTarget" type="string" default="";
	property name="defaultEvent" type="string" default="";
	// target and event to dispatch if an unknown event is handled (only applicable if implicitTasks is false)
	property name="undefinedTarget" type="string" default="";
	property name="undefinedEvent" type="string" default="";

	variables.controllers = {}; // controllers are static, so we need only one instance of each
	variables.tasks = {
		event = {},
		start = {},
		end = {},
		before = {},
		after = {}
	};

	// just create an instance of the default request strategy
	// if it is not needed, it will be garbage collected
	// assuming this will only occur once in the life of the application, it's not a big cost
	variables.requestStrategy = new DefaultRequestStrategy();

	/**
	 * Extracts the request parameters using the request strategy and starts the event handling cycle.
	 **/
	public Response function handleRequest() {

		var parameters = getRequestStrategy().collectParameters();

		// if no target or event is given, revert to the default target and/ or event
		var target = StructKeyExists(parameters, "target") ? parameters.target : variables.defaultTarget;
		var event = StructKeyExists(parameters, "event") ? parameters.event : variables.defaultEvent;

		return handleEvent(target, event, parameters);
	}

	/**
	 * Runs the event handling cycle.
	 **/
	public Response function handleEvent(required string targetName, required string eventType, struct parameters = {}) {

		var event = createEvent(arguments.targetName, arguments.eventType, arguments.parameters);

		runTasks(event);

		return event.getResponse();
	}

	/**
	 * Runs the before, after and event tasks associated with the event.
	 **/
	public boolean function dispatchEvent(required Event event, required string targetName, required string eventType) {

		local.targetName = arguments.event.getTarget();
		local.eventType = arguments.event.getType();
		arguments.event.setTarget(arguments.targetName);
		arguments.event.setType(arguments.eventType);

		var success = runBeforeTasks(arguments.event, arguments.targetName);

		if (success) {
			success = runEventTasks(arguments.event, arguments.targetName, arguments.eventType);
		}

		if (success) {
			success = runAfterTasks(arguments.event, arguments.targetName);
		}

		arguments.event.setTarget(local.targetName);
		arguments.event.setType(local.eventType);

		return success;
	}

	// TEMPLATE METHODS ===========================================================================

	/**
	 * Calls the template methods in order.
	 **/
	private void function runTasks(required Event event) {

		var targetName = arguments.event.getTarget();
		var eventType = arguments.event.getType();

		var success = runStartTasks(arguments.event);

		// only run the event task if we have success
		if (success) {
			success = dispatchEvent(arguments.event, targetName, eventType);
		}

		// the end tasks are always run, unless the event is aborted
		if (!arguments.event.isAborted()) {
			if (!success) {
				// for the remainder, we need an event object with its canceled flag revert
				arguments.event.revert();
			}

			runEndTasks(arguments.event);
		}

	}

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

		var success = true; // if nothing happens in this event, we still want to return true (an event does not have to be defined or have tasks)
		// check if there are tasks for this event
		var targetName = arguments.event.getTarget();
		var eventType = arguments.event.getType();
		if (StructKeyExists(variables.tasks.event, targetName) && StructKeyExists(variables.tasks.event[targetName], eventType)) {
			success = variables.tasks.event[targetName][eventType].run(arguments.event);
		} else {
			if (getImplicitTasks()) {
				var task = createPhaseTask();
				// if there is a controller with the name of the target, create an invoke task that invokes the handler by the name of the event type
				var controllerName = getComponentName(targetName, getControllerMapping());
				if (componentExists(controllerName)) {
					task.addSubtask(createInvokeTask(targetName, eventType));
				}
				// always create a render task that renders a view in a directory with the name of the target, that has the same name as the event type
				task.addSubtask(createRenderTask(targetName & "/" & eventType));
				// register this task, so that next time it is picked up immediately
				register(task, "event", targetName, eventType);

				success = task.run(arguments.event);
			} else {
				// dispatch the undefined event, if applicable
				if (Len(variables.undefinedTarget) > 0 && Len(variables.undefinedEvent) > 0 && (targetName != variables.undefinedTarget || eventType != variables.undefinedEvent)) {
					local.targetName = targetName;
					local.eventType = eventType;
					// if the current target exists, dispatch the event on that target, otherwise dispatch on the undefined target
					// also do that if the undefined event was dispatched already
					if (!StructKeyExists(variables.tasks.event, targetName) || eventType == variables.undefinedEvent) {
						local.targetName = variables.undefinedTarget;
					}
					local.eventType = variables.undefinedEvent;

					success = dispatchEvent(arguments.event, local.targetName, local.eventType);
				}
			}
		}

		return success;
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

	/**
	 * Returns the controller with the given name.
	 **/
	private component function getController(required string name) {

		if (!StructKeyExists(variables.controllers, arguments.name)) {
			var controllerName = getComponentName(arguments.name, getControllerMapping());
			if (!componentExists(controllerName)) {
				Throw(type = "cflow.request", message = "Controller #controllerName# does not exist");
			}

			variables.controllers[arguments.name] = new "#controllerName#"();
		}

		return variables.controllers[arguments.name];
	}

	/**
	 * Returns true if the component with the given name can be instantiated.
	 **/
	private boolean function componentExists(required string fullName) {

		var componentPath = ExpandPath("/" & Replace(arguments.fullName, ".", "/", "all") & ".cfc");

		return FileExists(componentPath);
	}

	private string function getComponentName(required string name, string mapping = "") {

		var componentName = arguments.name;
		if (Len(arguments.mapping) > 0) {
			componentName = arguments.mapping & "." & componentName;
		}

		return componentName;
	}

	/**
	 * Registers the task for the phase and target, and (if applicable) the event.
	 **/
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
					Throw(type = "cflow.request", message = "Event type is required when registering tasks for the event phase");
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
				Throw(type = "cflow.request", message = "Unknown phase '#arguments.phase#'");
				break;
		}

		phaseTask.addSubtask(arguments.task);

	}

	// FACTORY METHODS ============================================================================

	public InvokeTask function createInvokeTask(required string controllerName, required string handlerName) {
		return new InvokeTask(getController(arguments.controllerName), arguments.handlerName);
	}

	public DispatchTask function createDispatchTask(required string targetName, required string eventType) {
		return new DispatchTask(this, arguments.targetName, arguments.eventType);
	}

	public RenderTask function createRenderTask(required string view) {
		return new RenderTask(arguments.view, getViewMapping(), getRequestStrategy());
	}

	public RedirectTask function createRedirectTask(string url = "", string target = "", string event = "", struct parameters = {}, boolean permanent = false) {
		return new RedirectTask(arguments.url, arguments.target, arguments.event, arguments.parameters, arguments.permanent, getRequestStrategy());
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