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

component Context accessors="true" extends="cflow.req.Context" {

	property name="targetMapping" type="string" default="";

	variables.targets = {};

	public Response function handleEvent(required string targetName, required string eventType, struct parameters = {}) {

		var response = createResponse();
		var event = createEvent(arguments.parameters);

		getTarget(arguments.targetName).handleEvent(arguments.eventType, event, response);

		return response;
	}

	private Target function getTarget(required string name) {

		if (!StructKeyExists(variables.target, arguments.name)) {
			var targetName = getComponentName(arguments.name, getTargetMapping());
			if (componentExists(targetName)) {
				variables.targets[arguments.name] = new "#targetName#"();
			} else {
				if (arguments.name == getUndefinedTarget()) {
					Throw(type = "cflow.request", message = "The undefined target does not exist.");
				} else {
					// the target is not defined; try the undefined target
					variables.targets[arguments.name] = getTarget(getUndefinedTarget());
				}
			}
		}

		return variables.targets[arguments.name];
	}

}