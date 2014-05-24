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

component Event accessors="true" {

	property name="target" type="string" setter="false" default="";
	property name="type" type="string" setter="false" default="";
	property name="originalTarget" type="string" setter="false" default="";
	property name="originalType" type="string" setter="false" default="";

	variables.canceled = false;
	variables.aborted = false;
	variables.rejoin = true; // the event is in the page thread by default

	public void function init(required Context context, required Response response, required string target, required string type, struct properties = {}) {

		variables.context = arguments.context;
		variables.response = arguments.response;
		variables.target = arguments.target;
		variables.type = arguments.type;

		variables.originalTarget = arguments.target;
		variables.originalType = arguments.type;

		setProperties(arguments.properties);

	}

	public void function cancel() {
		variables.canceled = true;
	}

	public void function revert() {
		variables.canceled = false;
	}

	public boolean function isCanceled() {
		return variables.canceled;
	}

	public void function abort() {
		variables.aborted = true;
	}

	public boolean function isAborted() {
		return variables.aborted;
	}

	public struct function getProperties() {

		var properties = {};
		for (var property in this) {
			if (StructKeyExists(this, property) && !IsCustomFunction(this[property])) {
				properties[property] = this[property];
			}
		}

		return properties;
	}

	/**
	 * Puts properties on the object. Existing properties are kept (no overwrites).
	 **/
	public void function setProperties(required struct properties) {
		StructAppend(this, arguments.properties, false);
	}

	public boolean function willRejoin() {
		return variables.rejoin;
	}

	public boolean function dispatch(required string eventType) {

		var canceled = variables.canceled;
		variables.canceled = false;
		var success = variables.context.dispatchEvent(this, getTarget(), arguments.eventType);
		variables.canceled = canceled;

		return success;
	}

	// PACKAGE METHODS ============================================================================

	package Response function getResponse() {
		return variables.response;
	}

	package void function setTarget(required string value) {
		variables.target = arguments.value;
	}

	package void function setType(required string value) {
		variables.type = arguments.value;
	}

	package void function setRejoin(required boolean value) {
		variables.rejoin = arguments.value;
	}

	package void function merge(required Event event) {
		// merge the properties and the response
		setProperties(arguments.event.getProperties());
		variables.response.merge(arguments.event.getResponse());
	}

}