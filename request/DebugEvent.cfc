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

	public void function record(required string message, struct metadata = {}) {

		ArrayAppend(variables.messages, {
			message = arguments.message,
			metadata = arguments.metadata,
			target = getTarget(),
			event = getType(),
			tickcount = GetTickCount()
		});

	}

	public Event function clone() {
		return new DebugEvent(getTarget(), getType(), getProperties(), getResponse(), getMessages());
	}

	package array function getMessages() {
		return variables.messages;
	}

}