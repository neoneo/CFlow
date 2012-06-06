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

component Context extends="cflow.request.Context" {

	variables.outputRenderer = new OutputRenderer();

	public boolean function dispatchEvent(required Event event, required Response response, required string targetName, required string eventType) {

		arguments.event.record("Dispatch #arguments.targetName#.#arguments.eventType#");

		return super.dispatchEvent(arguments.event, arguments.response, arguments.targetName, arguments.eventType);
	}

	// FACTORY METHODS ============================================================================

	public Task function createInvokeTask(required string controllerName, required string methodName) {

		var task = super.createInvokeTask(argumentCollection = arguments);

		return new Task(task, arguments);
	}

	public Task function createDispatchTask(required string targetName, required string eventType, boolean cancelFailed = true) {

		var task = super.createDispatchTask(argumentCollection = arguments);

		return new DispatchTask(task, arguments);
	}

	public Task function createRenderTask(required string view) {

		var task = super.createRenderTask(argumentCollection = arguments);

		return new Task(task, arguments);
	}

	public Task function createRedirectTask(required string type, required struct parameters, boolean permanent = false) {

		var task = super.createRedirectTask(argumentCollection = arguments);

		return new RedirectTask(task, arguments);
	}

	public Task function createThreadTask(string action = "run", string name = "", string priority = "normal", numeric timeout = 0, numeric duration = 0) {

		var task = super.createThreadTask(argumentCollection = arguments);

		return new ThreadTask(task, arguments);
	}

	public Task function createIfTask(required string condition) {

		var task = super.createIfTask(argumentCollection = arguments);

		return new Task(task, arguments);
	}

	public Task function createElseTask(string condition = "") {

		var task = super.createElseTask(argumentCollection = arguments);

		return new Task(task, arguments);
	}

	public Task function createSetTask(required string name, required string expression, boolean overwrite = true) {

		var task = super.createSetTask(argumentCollection = arguments);

		return new SetTask(task, arguments);
	}

	public Event function createEvent(required string target, required string type, struct properties = {}) {
		return new Event(arguments.target, arguments.type, arguments.properties);
	}

	// TEMPLATE METHODS ===========================================================================

	private boolean function runStartTasks(required Event event, required Response response, required string targetName) {

		arguments.event.record("cflow.starttasks");

		try {
			var success = super.runStartTasks(arguments.event, arguments.response, arguments.targetName);
		} catch (any exception) {
			handleException(exception, arguments.event, arguments.response);
		}

		arguments.event.record("cflow.starttasks");

		return success;
	}

	private boolean function runBeforeTasks(required Event event, required Response response, required string targetName) {

		arguments.event.record("cflow.beforetasks");

		try {
			var success = super.runBeforeTasks(arguments.event, arguments.response, arguments.targetName);
		} catch (any exception) {
			handleException(exception, arguments.event, arguments.response);
		}

		arguments.event.record("cflow.beforetasks");

		return success;
	}

	private boolean function runAfterTasks(required Event event, required Response response, required string targetName) {

		arguments.event.record("cflow.aftertasks");

		try {
			var success = super.runAfterTasks(arguments.event, arguments.response, arguments.targetName);
		} catch (any exception) {
			handleException(exception, arguments.event, arguments.response);
		}

		arguments.event.record("cflow.aftertasks");

		return success;
	}

	private boolean function runEndTasks(required Event event, required Response response, required string targetName) {

		arguments.event.record("cflow.endtasks");

		try {
			var success = super.runEndTasks(arguments.event, arguments.response, arguments.targetName);
		} catch (any exception) {
			handleException(exception, arguments.event, arguments.response);
		}

		arguments.event.record("cflow.endtasks");

		return success;
	}

	private boolean function runEventTasks(required Event event, required Response response, required string targetName, required string eventType) {

		arguments.event.record("cflow.eventtasks");

		try {
			var success = super.runEventTasks(arguments.event, arguments.response, arguments.targetName, arguments.eventType);
		} catch (any exception) {
			handleException(exception, arguments.event, arguments.response);
		}

		arguments.event.record("cflow.eventtasks");

		return success;
	}

	private void function finalize(required Event event, required Response response) {
		renderOutput(arguments.event, arguments.response);
	}

	// OUTPUT METHODS =============================================================================

	private void function renderOutput(required Event event, required Response response) {

		// we're going to change the viewmapping temporarily
		// this might lead to race conditions in a production environment so debugging there is dangerous
		// to make sure the context remains consistent, we put this code inside a lock
		lock name="cflow.context" type="exclusive" timeout="1" {
			var viewMapping = getViewMapping();
			setViewMapping("/cflow/request/debug");
			// create a (non-debug) render task
			var task = super.createRenderTask("output");
			setViewMapping(viewMapping);
		}

		arguments.event._debugoutput = variables.outputRenderer.render(arguments.event.getMessages());
		task.run(arguments.event, arguments.response);

	}

	private void function handleException(required any exception, required Event event, required Response response) {

		arguments.event.record({exception: arguments.exception}, "cflow.exception");
		arguments.response.clear();
		renderOutput(arguments.event, arguments.response);
		response.write();
		abort;

	}

}