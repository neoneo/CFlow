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

	<cfproperty name="type" type="string">
	<cfproperty name="contentKey" type="string">

	<cfscript>

	public void function init() {

		variables.contentTypes = {
			html = "text/html",
			json = "application/json",
			xml = "application/xml",
			text = "text/plain"
		};
		variables.contents = [];
		variables.keys = [];
		variables.headers = [];

		setType("HTML");
		setContentKey("");

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

	public void function status(required numeric code, string text) {

		var header = {
			statuscode = arguments.code,
		}
		if (StructKeyExists(arguments, "text")) {
			header.text = arguments.text;
		}
		ArrayAppend(variables.headers, header);

	}

	/**
	 * Writes content to the output.
	 * The key argument can be a regular expression. All matched keys will be written to the output. If an empty string is passed in, all keys will be written (default).
	 * The clearContents argument determines whether the contents that are written will be cleared. If false, subsequent calls to write() may output the same content.
	 **/
	public void function write(string key = "", boolean clearContents = true) {

		var result = "";
		var writeContents = variables.contents;

		if (Len(arguments.key) > 0) {
			writeContents = [];

			// keys are not unique
			var keyCount = ArrayLen(variables.keys);
			for (var i = 1; i <= keyCount; i++) {
				if (IsValid("regex", variables.keys[i], arguments.key)) {
					ArrayAppend(writeContents, variables.contents[i]);
				}
			}
		}

		switch (variables.type) {
			case "html":
			case "text":
				for (var content in writeContents) {
					if (IsSimpleValue(content)) {
						result &= content;
					}
				}
				break;

			case "xml":
				var i = 0;
				for (var content in writeContents) {
					if (IsSimpleValue(content)) {
						i += 1;
						if (!IsXML(content)) {
							content = "<![CDATA[" & content & "]]>";
						}
						// TODO: handle the case if one of the parts already has a header <?xml?>
						result &= content;
					}
				}
				if (i != 1) {
					result = "<response>" & result & "</response>";
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
				if (IsValid("regex", variables.keys[i], arguments.key)) {
					ArrayDeleteAt(variables.contents, i);
					ArrayDeleteAt(variables.keys, i);
				}
			}
		}

	}

	/**
	 * Merges content and headers from the given Response instance onto the current instance.
	 **/
	public void function merge(required Response response) {

		var data = arguments.response.data();
		// append generated content
		var keyCount = ArrayLen(data.keys);
		for (var i = 1; i <= keyCount; i++) {
			append(data.contents[i], data.keys[i]);
		}
		// append headers
		for (var header in data.headers) {
			appendHeader(header.name, header.value);
		}

	}

	package struct function data() {
		return {
			keys = variables.keys,
			contents = variables.contents,
			headers = variables.headers
		};
	}
	</cfscript>

	<cffunction name="writeHeaders" access="public" output="false" returntype="void">

		<cfcontent type="#variables.contentTypes[getType()]#">
		<cfloop array="#variables.headers#" index="header">
			<cfheader attributecollection="#header#">
		</cfloop>

	</cffunction>

</cfcomponent>