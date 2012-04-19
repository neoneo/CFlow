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

	// target and event to dispatch if an unknown event is handled (only applicable if implicitTasks is false)
	property name="defaultTarget" type="string" default="";
	property name="defaultEvent" type="string" default="";

	variables.controllers = {}; // controllers are static, so we need only one instance of each
	variables.tasks = {
		event = {},
		start = {},
		end = {},
		before = {},
		after = {}
	};

	// just create an instance of the default request manager
	// if it is not needed, it will be garbage collected
	// assuming this will only occur once in the life of the application, it's not a big cost
	variables.requestStrategy = new DefaultRequestStrategy(this);

	public Response function handleRequest() {

		var parameters = getRequestStrategy().collectParameters();

		// if no target or event is given, revert to the welcome target and/ or event
		var target = StructKeyExists(parameters, "target") ? parameters.target : getDefaultTarget();
		var event = StructKeyExists(parameters, "event") ? parameters.event : getDefaultEvent();

		return handleEvent(target, event, parameters);
	}

	/**
	 * Fires an event on the given target.
	 **/
	public Response function handleEvent(required string targetName, required string eventType, struct parameters = {}) {

		var response = createResponse();
		var event = createRootEvent(arguments.targetName, arguments.eventType, arguments.parameters, response);

		var success = runStartTasks(event);

		// only run the event task if we have success
		if (success) {
			success = dispatchEvent(event);
		}

		// the end tasks are always run, unless the event was aborted
		if (!event.isAborted()) {
			if (!success) {
				// for the remainder, we need an event object with its canceled flag reset
				event = event.clone();
			}

			runEndTasks(event);
		}

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
				// if there is a controller with the name of the target, create an invoke task that invokes the method by the name of the event type
				var controllerName = getComponentName(targetName, getControllerMapping());
				if (componentExists(controllerName)) {
					task.addSubtask(createInvokeTask(targetName, eventType));
				}
				// always create a render task that renders a view in a directory with the name of the target, that has the same name as the event type
				task.addSubtask(createRenderTask(targetName & "/" & eventType));
				// add this task to the cache, so that next time we can reuse it
				variables.tasks.event[targetName][eventType] = task;
			} else {
				// dispatch the default event on the default target, if applicable
				if (Len(variables.defaultTarget) > 0 && Len(variables.defaultEvent) > 0 && targetName != variables.defaultTarget && eventType != variables.defaultEvent) {
					var event = createEvent(variables.defaultTarget, variables.defaultEvent, arguments.event);
					dispatchEvent(event);
				}
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

	/**
	 * Returns the controller with the given name.
	 **/
	private Controller function getController(required string name) {

		if (!StructKeyExists(variables.controllers, arguments.name)) {
			var controllerName = getComponentName(arguments.name, getControllerMapping());
			if (!componentExists(controllerName)) {
				Throw(type = "cflow.request", "Controller #controllerName# does not exist");
			}

			var controller = new "#controllerName#"(this);
			if (!IsInstanceOf(controller, "Controller")) {
				Throw(type = "cflow.request", "Controller #controllerName# does not extend cflow.request.Controller");
			}

			variables.controllers[arguments.name] = controller;
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

	// FACTORY METHODS ============================================================================

	public InvokeTask function createInvokeTask(required string controllerName, required string methodName) {
		return new InvokeTask(getController(arguments.controllerName), arguments.methodName);
	}

	public DispatchTask function createDispatchTask(required string targetName, required string eventType, boolean cancelFailed = true) {
		return new DispatchTask(this, arguments.targetName, arguments.eventType, arguments.cancelFailed);
	}

	public RenderTask function createRenderTask(required string view) {
		return new RenderTask(arguments.view, getViewMapping(), getRequestStrategy());
	}

	/**
	 * Creates a RedirectTask.
	 *
	 * @param	{String}	type		the redirect type: url or event
	 * @param	{Struct}	parameters	the parameters specific to the type of redirect (see below)
	 * @param	{Boolean}	permanent	whether the redirect is permanent or not [false]
	 *
	 * Redirect types:
	 * url		The parameters struct should have a url key that contains the explicit url to redirect to
	 * event	The parameters struct should have target and event keys, and may have additional keys that are used as url parameters
	 **/
	public RedirectTask function createRedirectTask(required string type, required struct parameters, boolean permanent = false) {
		return new RedirectTask(arguments.type, arguments.parameters, arguments.permanent, getRequestStrategy());
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

	/**
	 * Creates a new event object, based on the given event object.
	 **/
	package Event function createEvent(required string targetName, required string eventType, required Event event) {
		return new Event(arguments.targetName, arguments.eventType, arguments.event);
	}

	/**
	 * Creates a new event object. This method is only used for creating events that originate directly from a request. Further events are always created using createEvent().
	 **/
	private Event function createRootEvent(required string targetName, required string eventType, required struct properties, required Response response) {
		return new Event(arguments.targetName, arguments.eventType, arguments.properties, arguments.response);
	}

	private Response function createResponse() {
		return new Response();
	}

}