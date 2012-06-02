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

<cfcomponent displayname="Response" accessors="true" output="false">

	<cfproperty name="type" type="string" default="HTML">
	<cfproperty name="contentKey" type="string" default="">

	<cfscript>

	public void function init() {

		variables.contentTypes = {
			html = "text/html",
			json = "application/json",
			text = "text/plain"
		};
		variables.contents = [];
		variables.keys = [];
		variables.headers = [];

	}

	public void function append(required any content, string key = getContentKey()) {

		ArrayAppend(variables.contents, arguments.content);
		ArrayAppend(variables.keys, arguments.key);

	}

	public void function appendHeader(required string name, required string value) {

		ArrayAppend(variables.headers, {
			name = arguments.name,
			value = arguments.value
		});

	}

	/**
	 * Default implementation for writing html and json.
	 **/
	public void function write(string key = "", boolean clearContents = true) {

		var result = "";
		var writeContents = variables.contents;

		if (Len(arguments.key) > 0) {
			writeContents = [];

			// keys are not unique
			for (var i = 1; i <= ArrayLen(variables.keys); i++) {
				if (variables.keys[i] == arguments.key) {
					ArrayAppend(writeContents, variables.contents[i]);
				}
			}
		}

		switch (getType()) {
			case "html":
			case "text":
				for (var content in writeContents) {
					if (IsSimpleValue(content)) {
						result &= content;
					}
				}
				break;

			case "json":
				// if there is 1 element in the content, serialize that
				// if there are more, serialize the whole array
				var serializeContents = [];
				for (var content in writeContents) {
					if (!IsSimpleValue(content)) {
						ArrayAppend(serializeContents, content);
					}
				}
				result = ArrayLen(serializeContents) == 1 ? SerializeJSON(serializeContents[1]) : SerializeJSON(serializeContents);
				break;
		}

		WriteOutput(result);

		if (arguments.clearContents) {
			clear(arguments.key);
		}

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
	</cfscript>

	<cffunction name="writeHeaders" access="public" output="false" returntype="void">

		<cfcontent type="#variables.contentTypes[getType()]#">
		<cfloop array="#variables.headers#" index="header">
			<cfheader name="#header.name#" value="#header.value#">
		</cfloop>

	</cffunction>

</cfcomponent>