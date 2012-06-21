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

	property name="controllerMapping" type="string" default="";
	property name="viewMapping" type="string" default="";
	property name="requestStrategy" type="RequestStrategy";

	// target and event to dispatch if an unknown event is handled (only applicable if implicitTasks is false)
	property name="defaultTarget" type="string" default="";
	property name="defaultEvent" type="string" default="";
	property name="undefinedTarget" type="string" default="";
	property name="undefinedEvent" type="string" default="";

	// just create an instance of the default request strategy
	// if it is not needed, it will be garbage collected
	// assuming this will only occur once in the life of the application, it's not a big cost
	variables.requestStrategy = new DefaultRequestStrategy();

	variables.controllers = {};

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
		Throw(type = "cflow.notimplemented", message = "Not implemented");
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

}