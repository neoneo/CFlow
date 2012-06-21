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

component IfTask extends="ComplexTask" {

	public void function init(required string condition) {
		variables.evaluator = new cflow.util.Evaluator(arguments.condition);
	}

	public void function addSubtask(required Task task) {

		// the task is a subtask of this task as long as there is no else task
		// if there is one, the task is passed to the else task (also if the task is another ElseTask)
		// this mechanism results in a recursive if/ else structure
		if (StructKeyExists(variables, "elseTask")) {
			// add the subtask to the else task
			variables.elseTask.addSubtask(arguments.task);
		} else if (arguments.task.getType() == "else") {
			variables.elseTask = arguments.task;
		} else {
			super.addSubtask(arguments.task);
		}

	}

	public boolean function run(required Event event) {

		var success = true; // if the condition does not apply, return true
		if (variables.evaluator.execute(arguments.event)) {
			success = runSubtasks(arguments.event);
		} else if (StructKeyExists(variables, "elseTask")) {
			success = variables.elseTask.run(arguments.event);
		}

		return success;
	}

	public string function getType() {
		return "if";
	}

}