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

component PathInfoEndPoint implements="EndPoint" accessors="true" {

	property name="restPaths" type="array";
	property name="idPattern" type="string" default="[0-9]+";
	property name="defaultDocument" type="string" default="index.cfm";

	setRestPaths([]);

	public string function createUrl(required string target, required string event, struct parameters) {

		var path = getDefaultDocument();
		if (Len(path) > 0) {
			path = "/" & path
		}
		if (Len(arguments.target) > 0) {
			path &= "/" & arguments.target;
		}
		if (Len(arguments.event) > 0) {
			path &= "/" & arguments.event;
		}

		var queryString = "";
		if (StructKeyExists(arguments, "parameters") && !StructIsEmpty(arguments.parameters)) {
			for (var name in arguments.parameters) {
				queryString = ListAppend(queryString, name & "=" & UrlEncodedFormat(arguments.parameters[name]), "&");
			}
			queryString = "?" & queryString;
		}

		return path & queryString;
	}

	public struct function collectParameters() {

		var parameters = StructCopy(url);
		StructAppend(parameters, form, false);

		if (Len(cgi.path_info) > 1) {
			if (ArrayFind(getRestPaths(), function (path) {
				return Left(cgi.path_info, Len(arguments.path)) == arguments.path;
			}) > 0) {
				// REST request
				// split the path into parts and check if one or more parts are id's
				// the remaining parts together form the target
				// the following only works for paths of the form /author/1/book/2 (alternating name and id)
				// this will result in target 'author/book' and parameters author=1, book=2
				var parts = ListToArray(cgi.path_info, "/");
				var target = "";
				var pattern = getIdPattern();
				var name = "id"; // a default name for an id parameter if the path starts with one
				for (var part in parts) {
					part = UrlDecode(part);
					if (IsValid("regex", part, pattern)) {
						parameters[name] = part;
						name &= part; // append the part (the id) to the name in case the next part is also an id
					} else {
						target = ListAppend(target, part, "/");
						name = part; // if an id follows, its parameter will get this name
					}
				}
				parameters.target = target;
				parameters.event = LCase(cgi.request_method);
				// pick up the request body
				var headers = GetHTTPRequestData();
				var content = headers.content;
				parameters.content = content;
				switch (cgi.http_accept) {
					case "application/json":
						if (IsJSON(content)) {
							parameters.content = DeserializeJSON(content);
						}
						break;
					case "application/xml":
						if (IsXML(content)) {
							parameters.content = ParseXML(content);
						}
						break;
				}
			} else {
				var partCount = ListLen(cgi.path_info, "/");
				if (partCount > 1) {
					// the event is the last part, the first parts are the target
					parameters.target = ListDeleteAt(cgi.path_info, partCount, "/");
					parameters.event = ListLast(cgi.path_info, "/");
				} else {
					parameters.target = cgi.path_info;
					// event will revert to default
				}
				parameters.target = RemoveChars(parameters.target, 1, 1); // remove leading slash
			}
		}

		return parameters;
	}

}