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

component Event {

	variables.canceled = false;

	public void function init(required string target, required string type, required struct properties, required Response response) {

		variables.target = arguments.target;
		variables.type = arguments.type;
		variables.response = arguments.response;

		setProperties(arguments.properties);

	}

	public string function getTarget() {
		return variables.target;
	}

	public string function getType() {
		return variables.type;
	}

	public void function cancel() {
		variables.canceled = true;
	}

	public boolean function isCanceled() {
		return variables.canceled;
	}

	public void function abort() {
		abort;
	}

	public struct function getProperties() {

		var properties = {};
		for (var property in this) {
			if (!IsCustomFunction(this[property])) {
				properties[property] = this[property];
			}
		}

		return properties;
	}

	public void function setProperties(required struct properties) {

		for (var property in arguments.properties) {
			if (!StructKeyExists(this, property) || !IsCustomFunction(this[property])) {
				this[property] = arguments.properties[property];
			}
		}

	}

	/**
	* Returns a copy of the event, with its canceled flag reset.
	**/
	public Event function clone() {
		return new Event(getTarget(), getType(), getProperties(), getResponse());
	}

	package Response function getResponse() {
		return variables.response;
	}

}