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

import cflow.Event;

component DebugContext extends="cflow.Context" accessors="true" {

	// generateOutput property: always | exception | noredirect | never | <time in milliseconds>
	// the getter is defined below
	property name="generateOutput" type="string" getter="false";
	property name="remoteAddresses" type="array"; // address whitelist that receives output
	property name="serverName" type="string"; // only requests to this server name receive output
	property name="outputStrategy" type="DebugOutputStrategy";

	variables.generateOutput = "always";
	variables.outputStrategy = new DefaultDebugOutputStrategy();

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

		var generate = false;
		switch (getGenerateOutput(arguments.event)) {
			case "exception":
				generate = exceptionThrown;
				break;

			case "always":
			case "noredirect":
				generate = true;
				break;

		}
		if (generate) {
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

		var debugoutput = variables.outputStrategy.generate(arguments.event.getMessages());
		var response = arguments.event.getResponse();

		// get all the content from the response
		savecontent variable="local.content" {response.write();};

		// append the debugoutput, depending on the type of content
		switch (response.getType()) {
			case "HTML":
				if (local.content contains "</body>") {
					response.append(Replace(local.content, "</body>", debugoutput & "</body>"));
				} else {
					response.append(local.content);
					response.append(debugoutput);
				}
				break;

			case "JSON":
				// if the data is a struct, put the debugoutput on it
				// otherwise ignore it
				var data = DeserializeJSON(local.content);
				if (IsStruct(data)) {
					data["_debugoutput"] = ReplaceList(debugoutput, "#Chr(9)#,#Chr(10)#,#Chr(13)#", "");
				}
				response.append(data);
				break;

			default:
				response.append(local.content);
				response.append(debugoutput);
				break;

		}

	}

	/**
	 * Returns the display output setting, based on the context of the current request.
	 **/
	public string function getGenerateOutput(required Event event) {

		var generateOutput = variables.generateOutput;
		if ((!StructKeyExists(variables, "remoteAddresses") || ArrayFind(variables.remoteAddresses, cgi.remote_addr)) > 0
			&& (!StructKeyExists(variables, "serverName") || cgi.server_name == variables.serverName)) {
			if (IsNumeric(generateOutput)) {
				// the time allowed for the event to complete was set
				if (arguments.event.getTime() >= Val(generateOutput)) {
					// time has elapsed, always display
					generateOutput = "always";
				} else {
					// time has not yet elapsed, only display if an exception occurs
					generateOutput = "exception";
				}
			}
		} else {
			// request originates from address not on the whitelist
			generateOutput = "never";
		}

		return generateOutput;
	}

	// FACTORY METHODS ============================================================================

	public DebugTask function createInvokeTask(required string controllerName, required string handlerName) {

		var task = super.createInvokeTask(argumentCollection = arguments);

		return new DebugTask(task, arguments, this);
	}

	public DebugTask function createDispatchTask(required string targetName, required string eventType) {

		var task = super.createDispatchTask(argumentCollection = arguments);

		return new DebugDispatchTask(task, arguments, this);
	}

	public DebugTask function createRenderTask(required string view) {

		var task = super.createRenderTask(argumentCollection = arguments);

		return new DebugTask(task, arguments, this);
	}

	public DebugTask function createRedirectTask(string location = "", string target = "", string event = "", struct parameters = {}, boolean permanent = false) {

		var task = super.createRedirectTask(arguments.location, arguments.target, arguments.event, arguments.parameters, arguments.permanent);

		return new DebugRedirectTask(task, arguments, this);
	}

	public DebugTask function createThreadTask(string action = "run", string name = "", string priority = "normal", numeric timeout = 0, numeric duration = 0) {

		var task = super.createThreadTask(argumentCollection = arguments);

		return new DebugThreadTask(task, arguments, this);
	}

	public DebugTask function createIfTask(required string condition) {

		var task = super.createIfTask(argumentCollection = arguments);

		return new DebugTask(task, arguments, this);
	}

	public DebugTask function createElseTask(string condition = "") {

		var task = super.createElseTask(argumentCollection = arguments);

		return new DebugTask(task, arguments, this);
	}

	public DebugTask function createSetTask(required string name, required string expression, boolean overwrite = true) {

		var task = super.createSetTask(argumentCollection = arguments);

		return new DebugSetTask(task, arguments, this);
	}

	public DebugTask function createAbortTask() {

		var task = super.createAbortTask(argumentCollection = arguments);

		return new DebugTask(task, arguments, this);
	}

	public DebugTask function createCancelTask() {

		var task = super.createCancelTask(argumentCollection = arguments);

		return new DebugTask(task, arguments, this);
	}

	public DebugEvent function createEvent(required string target, required string type, struct properties = {}) {
		return new DebugEvent(this, createResponse(), arguments.target, arguments.type, arguments.properties);
	}

}