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

component Context extends="cflow.request.Context" accessors="true" {

	// displayOutput property: always | exception | noredirect | never | <time in milliseconds>
	// the getter is overridden below
	property name="displayOutput" type="string" default="always" getter="false";
	property name="remoteAddresses" type="array"; // array of addresses that receive output
	property name="serverName" type="string"; // only requests to this server name receive output

	public void function init() {

		variables.outputRenderer = new OutputRenderer();
		setViewMapping("/cflow/request/debug");
		// create a (non-debug) render task
		variables.debugRenderTask = super.createRenderTask("output");

	}

	// TEMPLATE METHODS ===========================================================================

	private void function runTasks(required Event event) {

		var exceptionThrown = false;
		try {
			super.runTasks(arguments.event);
		} catch (any exception) {
			// end all open recordStart() calls, so that the hierarchy is closed
			arguments.event.recordEndAll();
			exceptionThrown = true;
		}

		var display = false;
		switch (getDisplayOutput()) {
			case "exception":
				display = exceptionThrown;
				break;

			case "always":
			case "noredirect":
				display = true;
				break;

		}
		if (display) {
			renderOutput(arguments.event);
		}

	}

	private boolean function runStartTasks(required Event event) {

		arguments.event.recordStart("cflow.starttasks");

		var success = super.runStartTasks(arguments.event);

		arguments.event.recordEnd();

		return success;
	}

	private boolean function runBeforeTasks(required Event event) {

		arguments.event.recordStart("cflow.beforetasks");

		var success = super.runBeforeTasks(arguments.event);

		arguments.event.recordEnd();

		return success;
	}

	private boolean function runAfterTasks(required Event event) {

		arguments.event.recordStart("cflow.aftertasks");

		var success = super.runAfterTasks(arguments.event);

		arguments.event.recordEnd();

		return success;
	}

	private boolean function runEndTasks(required Event event) {

		arguments.event.recordStart("cflow.endtasks");

		var success = super.runEndTasks(arguments.event);

		arguments.event.recordEnd();

		return success;
	}

	private boolean function runEventTasks(required Event event) {

		arguments.event.recordStart("cflow.eventtasks");

		var success = super.runEventTasks(arguments.event);

		arguments.event.recordEnd();

		return success;
	}

	// OUTPUT METHODS =============================================================================

	private void function renderOutput(required Event event) {

		arguments.event._debugoutput = variables.outputRenderer.render(arguments.event.getMessages());
		variables.debugRenderTask.run(arguments.event);

	}

	/**
	 * Returns the display output setting, based on the context of the current request.
	 **/
	public string function getDisplayOutput() {

		var displayOutput = variables.displayOutput;
		if ((!StructKeyExists(variables, "remoteAddresses") || ArrayFind(variables.remoteAddresses, cgi.remote_addr)) > 0
			&& (!StructKeyExists(variables, "serverName") || cgi.server_name == variables.serverName)) {
			if (IsNumeric(displayOutput)) {
				// the time allowed for the event to complete was set
				if (arguments.event.getTime() >= Val(displayOutput)) {
					// time has elapsed, always display
					displayOutput = "always";
				} else {
					// time has not yet elapsed, only display if an exception occurs
					displayOutput = "exception";
				}
			}
		} else {
			// request originates from address not on the whitelist
			displayOutput = "never";
		}

		return displayOutput;
	}

	// FACTORY METHODS ============================================================================

	public Task function createInvokeTask(required string controllerName, required string handlerName) {

		var task = super.createInvokeTask(argumentCollection = arguments);

		return new Task(task, arguments, this);
	}

	public Task function createDispatchTask(required string targetName, required string eventType) {

		var task = super.createDispatchTask(argumentCollection = arguments);

		return new DispatchTask(task, arguments, this);
	}

	public Task function createRenderTask(required string view) {

		var task = super.createRenderTask(argumentCollection = arguments);

		return new Task(task, arguments, this);
	}

	public Task function createRedirectTask(string url = "", string target = "", string event = "", struct parameters = {}, boolean permanent = false) {

		var task = super.createRedirectTask(argumentCollection = arguments);

		return new RedirectTask(task, arguments, this);
	}

	public Task function createThreadTask(string action = "run", string name = "", string priority = "normal", numeric timeout = 0, numeric duration = 0) {

		var task = super.createThreadTask(argumentCollection = arguments);

		return new ThreadTask(task, arguments, this);
	}

	public Task function createIfTask(required string condition) {

		var task = super.createIfTask(argumentCollection = arguments);

		return new Task(task, arguments, this);
	}

	public Task function createElseTask(string condition = "") {

		var task = super.createElseTask(argumentCollection = arguments);

		return new Task(task, arguments, this);
	}

	public Task function createSetTask(required string name, required string expression, boolean overwrite = true) {

		var task = super.createSetTask(argumentCollection = arguments);

		return new SetTask(task, arguments, this);
	}

	public Task function createAbortTask() {

		var task = super.createAbortTask(argumentCollection = arguments);

		return new Task(task, arguments, this);
	}

	public Task function createCancelTask() {

		var task = super.createCancelTask(argumentCollection = arguments);

		return new Task(task, arguments, this);
	}

	public Event function createEvent(required string target, required string type, struct properties = {}) {
		return new Event(this, createResponse(), arguments.target, arguments.type, arguments.properties);
	}

}