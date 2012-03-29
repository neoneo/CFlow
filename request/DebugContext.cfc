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

component DebugContext extends="Context" {

	// FACTORY METHODS ============================================================================

	public DebugTask function createInvokeTask(required string controllerName, required string methodName) {

		var task = super.createInvokeTask(argumentCollection = arguments);

		return new DebugTask(task, arguments);
	}

	public DebugTask function createDispatchTask(required string targetName, required string eventType, boolean cancelFailed = true) {

		var task = super.createDispatchTask(argumentCollection = arguments);

		return new DebugTask(task, arguments);
	}

	public DebugTask function createRenderTask(required string view) {

		var task = super.createRenderTask(argumentCollection = arguments);

		return new DebugTask(task, arguments);
	}

	public RedirectDebugTask function createRedirectTask(required string type, required struct parameters, boolean permanent = false) {
		return new RedirectDebugTask(arguments.type, arguments.parameters, arguments.permanent, getRequestStrategy());
	}

	public DebugTask function createEvaluateTask(required string condition) {

		var task = super.createEvaluateTask(argumentCollection = arguments);

		return new DebugTask(task, arguments);
	}

	package Event function createEvent(required string targetName, required string eventType, required struct event, Response response) {

		var properties = JavaCast("null", 0);
		var response = JavaCast("null", 0);
		var messages = JavaCast("null", 0);

		// some code duplication from Context
		if (IsInstanceOf(arguments.event, "Event")) {
			properties = arguments.event.getProperties();
			response = arguments.event.getResponse();
			messages = arguments.event.getMessages();
		} else {
			properties = arguments.event;
			response = arguments.response;
			messages = [];
		}

		return new DebugEvent(arguments.targetName, arguments.eventType, properties, response, messages);
	}

	// TEMPLATE METHODS ===========================================================================

	private boolean function runStartTasks(required Event event) {

		arguments.event.record("cflow.starttasks");

		try {
			var success = super.runStartTasks(arguments.event);
		} catch (any e) {
			handleException(e, arguments.event);
		}

		arguments.event.record("cflow.starttasks");

		return success;
	}

	private boolean function runBeforeTasks(required Event event) {

		arguments.event.record("cflow.beforetasks");

		try {
			var success = super.runBeforeTasks(arguments.event);
		} catch (any e) {
			handleException(e, arguments.event);
		}

		arguments.event.record("cflow.beforetasks");

		return success;
	}

	private boolean function runAfterTasks(required Event event) {

		arguments.event.record("cflow.aftertasks");

		try {
			var success = super.runAfterTasks(arguments.event);
		} catch (any e) {
			handleException(e, arguments.event);
		}

		arguments.event.record("cflow.aftertasks");

		return success;
	}

	private boolean function runEndTasks(required Event event) {

		arguments.event.record("cflow.endtasks");

		try {
			var success = super.runEndTasks(arguments.event);
		} catch (any e) {
			handleException(e, arguments.event);
		}

		arguments.event.record("cflow.endtasks");

		// render debug output
		renderDebugOutput(arguments.event);

		return success;
	}

	private boolean function runEventTasks(required Event event) {

		arguments.event.record("cflow.eventtasks");

		try {
			var success = super.runEventTasks(arguments.event);
		} catch (any e) {
			handleException(e, arguments.event);
		}

		arguments.event.record("cflow.eventtasks");

		return success;
	}

	private void function renderDebugOutput(required Event event) {

		// we're going to change the viewmapping temporarily
		// this might lead to race conditions in a production environment so debugging there is dangerous
		// to make sure the context remains consistent, we put this code inside a lock
		lock name="cflow.context" type="exclusive" timeout="1" {
			var viewMapping = getViewMapping();
			setViewMapping("/cflow/request");
			// create a (non-debug) render task
			var task = super.createRenderTask("debugoutput");
			setViewMapping(viewMapping);
		}

		arguments.event._debugoutput = new DebugOutputRenderer().render(arguments.event.getMessages());

		task.run(arguments.event);

	}

	private void function handleException(required any exception, required Event event) {

		arguments.event.record({exception: exception}, "cflow.exception");
		var response = arguments.event.getResponse();
		response.clear();
		renderDebugOutput(arguments.event);
		response.write();
		abort;

	}

}