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

component InvokeTask extends="DebugComplexTask" {

	public void function init(required Task task, required struct metadata, required Context context) {
		super.init(argumentCollection = arguments);
		// inject the getter and setter for the controller property
		arguments.task.setController = setController;
		arguments.task.getController = getController;
		variables.controllerMapping = GetMetadata(arguments.task.getController()).name;
	}

	public boolean function run(required Event event) {
		if (!variables.context.getCacheControllers()) {
			variables.task.setController(new "#variables.controllerMapping#"());
		}

		return super.run(arguments.event);
	}

	private void function setController(required component controller) {
		variables.controller = arguments.controller;
	}

	private component function getController() {
		return variables.controller;
	}

}