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

	public void function init(required string target, required string type, required struct properties, required Response response, array messages = []) {

		variables.messages = arguments.messages;
		super.init(arguments.target, arguments.type, arguments.properties, arguments.response);

	}

	public void function cancel() {

		record("cflow.eventcanceled");
		super.cancel();

	}

	public void function abort() {

		record("cflow.aborted");
		// aborting means that no more output is written
		variables.response.clear();

	}

	public boolean function isAborted() {

		// the messages array is shared among all the event objects created during processing
		// since we need to know if some event aborted, we check that array for its last message
		var aborted = false;
		var size = ArrayLen(variables.messages);
		if (size > 0) {
			aborted = variables.messages[size].message == "cflow.aborted";
		}

		return aborted;
	}

	public void function record(required string message, any metadata) {

		// we only accept messages if the event is not aborted, because in effect the whole request cycle should have ended already (we're only mimicking this for debugging)
		if (!isAborted()) {
			var message = {
				message = arguments.message,
				target = getTarget(),
				event = getType(),
				tickcount = GetTickCount()
			};
			if (StructKeyExists(arguments, "metadata")) {
				message.metadata = arguments.metadata;
			}
			ArrayAppend(variables.messages, message);
		}

	}

	public Event function clone() {
		return new DebugEvent(getTarget(), getType(), getProperties(), getResponse(), getMessages());
	}

	package array function getMessages() {
		return variables.messages;
	}

}