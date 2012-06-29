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

component Result {

	variables.messages = collection(); // we use an argument collection, because it keeps the order of the keys that are added
	variables.passed = true;

	public void function addMessages(required string name, required array messages) {

		variables.messages[arguments.name] = arguments.messages;
		if (!ArrayIsEmpty(arguments.messages)) {
			variables.passed = false;
		}

	}

	public void function addMessage(required string name, required string message) {

		if (!StructKeyExists(variables.messages, arguments.name)) {
			variables.messages[arguments.name] = [];
		}
		ArrayAppend(variables.messages[arguments.name], arguments.message);
		variables.passed = false;

	}

	public boolean function isPassed(string name) {

		var passed = variables.passed;
		if (StructKeyExists(arguments, "name")) {
			// the rules must have been tested (so the struct key exists), and must have resulted in 0 messages
			passed = StructKeyExists(variables.messages, arguments.name) && ArrayIsEmpty(variables.messages[arguments.name]);
		}

		return passed;
	}

	public array function getNames() {
		return StructKeyArray(variables.messages);
	}

	public array function getMessages(required string name) {

		var messages = JavaCast("null", 0);
		if (StructKeyExists(variables.messages, arguments.name)) {
			messages = variables.messages[arguments.name];
		} else {
			messages = [];
		}

		return messages;
	}

	private array function collection() {
		return arguments;
	}

}