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

component Response accessors="true" {

	property name="type" type="string" default="HTML";
	property name="writeKey" type="string" default="";

	include "../static/content.cfm"; // include the content() function, that calls cfcontent to set the content type

	public void function init() {

		variables.contentTypes = {
			html = "text/html",
			json = "application/json",
			text = "text/plain"
		};
		variables.contents = [];
		variables.keys = [];
		variables.contentTypeSet = false;

	}

	public void function write(required any content, string key = getWriteKey()) {
		ArrayAppend(variables.contents, arguments.content);
		ArrayAppend(variables.keys, arguments.key);
	}

	/**
	 * Default implementation for rendering html and json.
	 **/
	public void function render(string key = "") {

		var result = "";
		var outputContents = variables.contents;

		if (Len(arguments.key) > 0) {
			outputContents = [];

			for (var i = 1; i <= ArrayLen(variables.keys); i++) {
				if (variables.keys[i] == arguments.key) {
					ArrayAppend(outputContents, variables.contents[i]);
				}
			}
		}

		if (!variables.contentTypeSet) {
			// set the content header
			content(variables.contentTypes[getType()]);
			variables.contentTypeSet = true;
		}

		switch (getType()) {
			case "html":
			case "text":
				for (var content in outputContents) {
					if (IsSimpleValue(content)) {
						result &= content;
					}
				}
				break;
			case "json":
				// if there is 1 element in the content, serialize that
				// if there are more, serialize the whole array
				if (ArrayLen(outputContents) == 1) {
					result = SerializeJSON(outputContents[1]);
				} else {
					result = SerializeJSON(outputContents);
				}
				break;
		}

		WriteOutput(result);
	}

	public void function clear(string key = "") {

		if (Len(arguments.key) == 0) {
			ArrayClear(variables.contents);
			ArrayClear(variables.keys);
		} else {
			// the key doesn't have to exist, or there can be more than one occurrence
			for (var i = ArrayLen(variables.keys); i >= 1; i--) {
				if (variables.keys[i] == arguments.key) {
					ArrayDeleteAt(variables.contents, i);
					ArrayDeleteAt(variables.keys, i);
				}
			}
		}

	}

}