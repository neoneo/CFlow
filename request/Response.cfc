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

component Response {

	include "content.cfm"; // include the content() function, that calls cfcontent to set the content type

	public void function init() {

		variables.type = "HTML";
		variables.contentTypes = {
			HTML = "text/html",
			JSON = "application/json",
			TEXT = "text/plain"
		};
		variables.contents = [];

	}

	public void function setType(required string type) {
		variables.type = arguments.type;
	}

	public string function getType() {
		return variables.type;
	}

	public void function write(required any content) {
		ArrayAppend(variables.contents, arguments.content);
	}

	/**
	 * Default implementation for rendering HTML and JSON.
	 **/
	public void function render() {

		var result = "";
		var contents = variables.contents;

		// set the content header
		content(variables.contentTypes[getType()]);

		switch (getType()) {
			case "HTML":
			case "TEXT":
				for (var content in contents) {
					if (IsSimpleValue(content)) {
						result &= content;
					}
				}
				break;
			case "JSON":
				// if there is 1 element in the content, serialize that
				// if there are more, serialize the whole array
				if (ArrayLen(contents) == 1) {
					result = SerializeJSON(contents[1]);
				} else {
					result = SerializeJSON(contents);
				}
				break;
		}

		//clear();

		WriteOutput(result);
	}

	public void function clear() {
		ArrayClear(variables.contents);
	}

}