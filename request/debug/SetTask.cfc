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

component SetTask extends="Task" {

	private void function recordStart(required Event event, required struct metadata) {

		// the exists boolean tells whether the variable already existed before the task is run
		arguments.metadata.exists = StructKeyExists(arguments.event, arguments.metadata.name);
		super.recordStart(arguments.event, arguments.metadata);

	}

	private void function recordEnd(required Event event, required struct metadata) {

		// now we can get the value from the event
		// if the task has caused an exception, the value will not have been set
		// in that case the event is aborted (if the event was aborted before the task was run, we wouldn't arrive here)
		if (!arguments.event.isAborted()) {
			arguments.metadata.value = arguments.event[arguments.metadata.name];
		}
		super.recordEnd(arguments.event, arguments.metadata);

	}

}