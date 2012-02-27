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
	property name="requestManager" type="RequestManager";

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
	variables.requestManager = new DefaultRequestManager(this);

	public void function setDefaultTarget(required string targetName) {
		getRequestManager().setDefaultTarget(arguments.targetName);
	}

	public void function setDefaultEvent(required string eventType) {
		getRequestManager().setDefaultEvent(arguments.eventType);
	}

	public Response function handleRequest() {
		return getRequestManager().handleRequest();
	}

	/**
	 * Fires an event on the given target.
	 **/
	public Response function handleEvent(required string targetName, required string eventType, struct properties = {}) {

		var response = createResponse();
		var event = createEvent(arguments.targetName, arguments.eventType, arguments.properties, response);

		var success = runStartTasks(event);

		// only run the event task if we have success
		if (success) {
			success = dispatchEvent(event);
		}

		// the end tasks are always run
		if (!success) {
			// for the remainder, we need an event object with its canceled flag reset
			event = event.clone();
		}

		runEndTasks(event);

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
					throw(type = "cflow", message = "Event type is required when registering tasks for the event phase");
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
				throw(type = "cflow", message = "Unknown phase '#arguments.phase#'");
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
				// we now assume there is a controller with the name of the target, that exposes a method with the name of the event type
				task.addSubtask(createInvokeTask(targetName, eventType));
				// and that there is a template in a directory with the name of the target, that has the same name as the event type
				task.addSubtask(createRenderTask(targetName & "/" & eventType));
				// add this task to the cache, so that next time we can reuse it
				variables.tasks.event[targetName][eventType] = task;
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

	private Controller function getController(required string name) {

		if (!StructKeyExists(variables.controllers, arguments.name)) {
			var controllerName = arguments.name;
			if (Len(getControllerMapping()) > 0) {
				controllerName = getControllerMapping() & "." & controllerName;
			}
			variables.controllers[arguments.name] = new "#controllerName#"(this);
		}

		return variables.controllers[arguments.name];
	}

	// FACTORY METHODS ============================================================================

	public InvokeTask function createInvokeTask(required string controllerName, required string methodName) {
		return new InvokeTask(getController(arguments.controllerName), arguments.methodName);
	}

	public DispatchTask function createDispatchTask(required string targetName, required string eventType, boolean cancelFailed = true) {
		return new DispatchTask(this, arguments.targetName, arguments.eventType, arguments.cancelFailed);
	}

	public RenderTask function createRenderTask(required string template) {

		var templateLocation = arguments.template;
		if (Len(getViewMapping()) > 0) {
			templateLocation = getViewMapping() & "/" & arguments.template;
		}

		return new RenderTask(templateLocation, getRequestManager());
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
	public RedirectTask function createRedirectTask(required any type, required any parameters, boolean permanent = false) {
		return new RedirectTask(arguments.type, arguments.parameters, arguments.permanent, getRequestManager());
	}

	public PhaseTask function createPhaseTask() {
		return new PhaseTask();
	}

	package Event function createEvent(required string targetName, required string eventType, required struct event, Response response) {

		var properties = JavaCast("null", 0);
		var response = JavaCast("null", 0);

		// if event is an Event, we take the response from there
		// if not, we expect a Response object in the arguments
		if (IsInstanceOf(arguments.event, "Event")) {
			properties = arguments.event.getProperties();
			response = arguments.event.getResponse();
		} else {
			properties = arguments.event;
			response = arguments.response;
		}

		return new Event(arguments.targetName, arguments.eventType, properties, response);
	}

	private Response function createResponse() {
		return new Response();
	}

}