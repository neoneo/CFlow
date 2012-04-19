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

component DebugEvent extends="Event" {

	public void function init(required string target, required string type, required struct properties, Response response) {

		super.init(argumentCollection = arguments);
		if (IsInstanceOf(arguments.properties, "Event")) {
			variables.messages = arguments.properties.getMessages();
		} else {
			variables.messages = [];
		}

	}

	public void function cancel() {

		record("cflow.eventcanceled");
		super.cancel();

	}

	public void function abort() {

		var size = ArrayLen(variables.messages);
		if (size == 0 || variables.messages[size].message != "cflow.aborted") {
			record("cflow.aborted");
		}
		super.abort();

	}

	public DebugEvent function clone() {
		return new DebugEvent(getTarget(), getType(), this);
	}

	public void function record(required any metadata, string message = "") {

		// if the metadata is a simple value and message is not defined, we interpret metadata as the message
		local.message = arguments.message;
		if (IsSimpleValue(arguments.metadata) && Len(arguments.message) == 0) {
			local.message = arguments.metadata;
		} else {
			local.metadata = arguments.metadata;
		}
		var transport = {
			message = Len(local.message) > 0 ? local.message : "Dump",
			target = getTarget(),
			event = getType(),
			tickcount = GetTickCount()
		};
		if (StructKeyExists(local, "metadata")) {
			transport.metadata = local.metadata;
		}
		ArrayAppend(variables.messages, transport);

	}

	package array function getMessages() {
		return variables.messages;
	}

}