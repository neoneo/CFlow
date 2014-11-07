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

component SetTask extends="DebugTask" {

	private void function debugStart(required Event event, required struct metadata) {

		// the exists boolean tells whether the variable already existed before the task is run
		arguments.metadata.exists = StructKeyExists(arguments.event, arguments.metadata.name);
		super.debugStart(arguments.event, arguments.metadata);

	}

	private void function debugEnd(required Event event, required struct metadata) {

		// now we can get the value from the event
		arguments.metadata.value = arguments.event[arguments.metadata.name];
		super.debugEnd(arguments.event, arguments.metadata);

	}

}