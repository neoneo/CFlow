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

component ThreadTask extends="DebugComplexTask" {

	private void function recordEnd(required Event event, required struct metadata) {

		// if this is a join action, merge the event messages on the current event object
		if (arguments.metadata.action == "join") {
			// loop over the joined threads
			var names = ListToArray(arguments.metadata.name);
			for (var name in names) {
				// pick up the messages from the thread event object
				// it is possible that the thread is terminated before the event object is created, so check for that
				arguments.event.record({
					name = name,
					status = cfthread[name].status,
					messages = StructKeyExists(cfthread[name], "event") ? cfthread[name].event.getMessages() : []
				}, "cflow.joinedthread");
			}
		}

		super.recordEnd(arguments.event, arguments.metadata);

	}

}