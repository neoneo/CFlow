<!---
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
--->

component DebugDispatchTask extends="DispatchTask" {

	public void function init(required Context context, required string targetName, required string eventType, boolean cancelFailed = true) {

		variables.metadata = StructCopy(arguments);
		StructDelete(variables.metadata, "context");
		variables.metadata.type = getType();
		super.init(argumentCollection = arguments);

	}

	public boolean function run(required Event event) {

		success = true;

		if (!arguments.event.isAborted()) {
			var metadata = StructCopy(variables.metadata);
			// get the target and event that are actually going to be dispatched
			metadata.dispatchTargetName = variables.targetParameter.getValue(arguments.event);
			metadata.dispatchEventType = variables.eventType.getValue(arguments.event);

			arguments.event.record(metadata, "cflow.task");

			success = super.run(arguments.event);

			arguments.event.record(metadata, "cflow.task");
		}

		return success;
	}

}