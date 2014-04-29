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

component DebugDispatchTask extends="DebugComplexTask" {

	private void function recordStart(required Event event, required struct metadata) {
		// append the target and event that are actually going to be dispatched
		arguments.metadata.dispatchTargetName = variables.task.getTargetName(arguments.event);
		arguments.metadata.dispatchEventType = variables.task.getEventType(arguments.event);

		super.recordStart(arguments.event, arguments.metadata);

	}

}