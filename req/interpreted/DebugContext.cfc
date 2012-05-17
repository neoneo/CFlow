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

	variables.debugOutputRenderer = new DebugOutputRenderer();

	public boolean function dispatchEvent(required DebugEvent event, required string targetName, required string eventType) {

		arguments.event.record("Dispatch #arguments.targetName#.#arguments.eventType#");

		return super.dispatchEvent(arguments.event, arguments.targetName, arguments.eventType);
	}

	// FACTORY METHODS ============================================================================

	public DebugTask function createInvokeTask(required string controllerName, required string methodName) {

		var task = super.createInvokeTask(argumentCollection = arguments);

		return new DebugTask(task, arguments);
	}

	public DebugDispatchTask function createDispatchTask(required string targetName, required string eventType, boolean cancelFailed = true) {
		return new DebugDispatchTask(this, arguments.targetName, arguments.eventType, arguments.cancelFailed);
	}

	public DebugTask function createRenderTask(required string view) {

		var task = super.createRenderTask(argumentCollection = arguments);

		return new DebugTask(task, arguments);
	}

	public RedirectDebugTask function createRedirectTask(required string type, required struct parameters, boolean permanent = false) {
		return new RedirectDebugTask(arguments.type, arguments.parameters, arguments.permanent, getRequestStrategy());
	}

	public DebugTask function createIfTask(required string condition) {

		var task = super.createIfTask(argumentCollection = arguments);

		return new DebugTask(task, arguments);
	}

	public DebugTask function createElseTask(string condition = "") {

		var task = super.createElseTask(argumentCollection = arguments);

		return new DebugTask(task, arguments);
	}

	public DebugSetTask function createSetTask(required string name, required string expression, boolean overwrite = true) {
		return new DebugSetTask(arguments.name, arguments.expression, arguments.overwrite);
	}

	package DebugEvent function createEvent(required struct properties, required Response response) {
		return new DebugEvent(arguments.properties, arguments.response);
	}

	// TEMPLATE METHODS ===========================================================================

	private boolean function runStartTasks(required DebugEvent event, required string targetName) {

		arguments.event.record("cflow.starttasks");

		try {
			var success = super.runStartTasks(arguments.event, arguments.targetName);
		} catch (any e) {
			handleException(e, arguments.event);
		}

		arguments.event.record("cflow.starttasks");

		return success;
	}

	private boolean function runBeforeTasks(required DebugEvent event, required string targetName) {

		arguments.event.record("cflow.beforetasks");

		try {
			var success = super.runBeforeTasks(arguments.event, arguments.targetName);
		} catch (any e) {
			handleException(e, arguments.event);
		}

		arguments.event.record("cflow.beforetasks");

		return success;
	}

	private boolean function runAfterTasks(required DebugEvent event, required string targetName) {

		arguments.event.record("cflow.aftertasks");

		try {
			var success = super.runAfterTasks(arguments.event, arguments.targetName);
		} catch (any e) {
			handleException(e, arguments.event);
		}

		arguments.event.record("cflow.aftertasks");

		return success;
	}

	private boolean function runEndTasks(required DebugEvent event, required string targetName) {

		arguments.event.record("cflow.endtasks");

		try {
			var success = super.runEndTasks(arguments.event, arguments.targetName);
		} catch (any e) {
			handleException(e, arguments.event);
		}

		arguments.event.record("cflow.endtasks");

		return success;
	}

	private boolean function runEventTasks(required DebugEvent event, required string targetName, required string eventType) {

		arguments.event.record("cflow.eventtasks");

		try {
			var success = super.runEventTasks(arguments.event, arguments.targetName, arguments.eventType);
		} catch (any e) {
			handleException(e, arguments.event);
		}

		arguments.event.record("cflow.eventtasks");

		return success;
	}

	private void function finalize(required DebugEvent event) {
		renderDebugOutput(arguments.event);
	}

	// DEBUG OUTPUT METHODS =======================================================================

	private void function renderDebugOutput(required DebugEvent event) {

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

		arguments.event._debugoutput = variables.debugOutputRenderer.render(arguments.event.getMessages());
		task.run(arguments.event);

	}

	private void function handleException(required any exception, required DebugEvent event) {

		arguments.event.record({exception: exception}, "cflow.exception");
		var response = arguments.event.getResponse();
		response.clear();
		renderDebugOutput(arguments.event);
		response.write();
		abort;

	}

}