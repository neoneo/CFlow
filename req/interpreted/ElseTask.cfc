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

component ElseTask extends="IfTask" {

	public void function init(string condition = "") {

		if (Len(arguments.condition) > 0) {
			super.init(arguments.condition);
			variables.hasCondition = true;
		} else {
			variables.hasCondition = false;
		}

	}

	public boolean function run(required Event event) {

		if (!variables.hasCondition) {
			// the subtasks have to run unconditionally
			runSubtasks(arguments.event);
		} else {
			// conditional running of subtasks, which is implemented in the superclass
			super.run(arguments.event);
		}

		return true;
	}

	public string function getType() {
		return "else";
	}

}