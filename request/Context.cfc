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
	variables.requestStrategy = new DefaultRequestStrategy(this);

	public Response function handleRequest() {

		var parameters = getRequestStrategy().collectParameters();

		// if no target or event is given, revert to the default target and/ or event
		var target = StructKeyExists(parameters, "target") ? parameters.target : variables.defaultTarget;
		var event = StructKeyExists(parameters, "event") ? parameters.event : variables.defaultEvent;

		return handleEvent(target, event, parameters);
	}

	/**
	 * Fires an event on the given target.
	 **/
	public Response function handleEvent(required string targetName, required string eventType, struct parameters = {}) {

		var response = createResponse();
		var event = createEvent(arguments.parameters, response);
		event.setTarget(targetName);
		event.setType(eventType);

		var success = runStartTasks(event, arguments.targetName);

		// only run the event task if we have success
		if (success) {
			success = dispatchEvent(event, arguments.targetName, arguments.eventType);
		}

		// the end tasks are always run, unless the event is aborted
		if (!event.isAborted()) {
			if (!success) {
				// for the remainder, we need an event object with its canceled flag reset
				event.reset();
			}

			runEndTasks(event, arguments.targetName);
		}

		// basically, finalize() is only provided as a hook for DebugContext
		// maybe there are other needs for it, but if not, find a way to factor this out
		finalize(event);

		return response;
	}

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

	private boolean function runStartTasks(required Event event, required string targetName) {
		return getPhaseTask("start", arguments.targetName).run(arguments.event);
	}

	private boolean function runBeforeTasks(required Event event, required string targetName) {
		return getPhaseTask("before", arguments.targetName).run(arguments.event);
	}

	private boolean function runAfterTasks(required Event event, required string targetName) {
		return getPhaseTask("after", arguments.targetName).run(arguments.event);
	}

	private boolean function runEndTasks(required Event event, required string targetName) {
		return getPhaseTask("end", arguments.targetName).run(arguments.event);
	}

	private boolean function runEventTasks(required Event event, required string targetName, required string eventType) {

		var result = true;
		// check if there are tasks for this event
		if (StructKeyExists(variables.tasks.event, arguments.targetName) && StructKeyExists(variables.tasks.event[arguments.targetName], arguments.eventType)) {
			result = variables.tasks.event[arguments.targetName][arguments.eventType].run(arguments.event);
		} else {
			if (getImplicitTasks()) {
				var task = createPhaseTask();
				// if there is a controller with the name of the target, create an invoke task that invokes the method by the name of the event type
				var controllerName = getComponentName(arguments.targetName, getControllerMapping());
				if (componentExists(controllerName)) {
					task.addSubtask(createInvokeTask(arguments.targetName, arguments.eventType));
				}
				// always create a render task that renders a view in a directory with the name of the target, that has the same name as the event type
				task.addSubtask(createRenderTask(arguments.targetName & "/" & arguments.eventType));
				// register this task, so that next time we can reuse it
				register(task, "event", arguments.targetName, arguments.eventType);

				result = task.run(arguments.event);
			} else {
				// dispatch the undefined event, if applicable
				if (Len(variables.undefinedTarget) > 0 && Len(variables.undefinedEvent) > 0 && (arguments.targetName != variables.undefinedTarget || arguments.eventType != variables.undefinedEvent)) {
					local.targetName = arguments.targetName;
					local.eventType = arguments.eventType;
					// if the current target exists, dispatch the event on that target, otherwise dispatch on the undefined target
					// also do that if the undefined event was dispatched already
					if (!StructKeyExists(variables.tasks.event, arguments.targetName) || arguments.eventType == variables.undefinedEvent) {
						local.targetName = variables.undefinedTarget;
					}
					local.eventType = variables.undefinedEvent;

					//var event = createEvent(arguments.targetName, arguments.eventType, arguments.event);
					result = dispatchEvent(arguments.event, local.targetName, local.eventType);
				}
			}
		}

		return result;
	}

	private void function finalize(required Event event) {
		// hook
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
	 * url		The parameters struct should have a url key that contains the url to redirect to
	 * event	The parameters struct should have target and event keys
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

	private Event function createEvent(required struct parameters, required Response response) {
		return new Event(arguments.parameters, arguments.response);
	}

	private Response function createResponse() {
		return new Response();
	}

}