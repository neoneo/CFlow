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

component PathInfoRequestStrategy implements="RequestStrategy" accessors="true" {

	property name="restPaths" type="array";

	setRestPaths([]);

	public string function createUrl(required string target, required string event, struct parameters) {

		var path = "";
		if (Len(arguments.target) > 0) {
			path = "/" & UrlEncodedFormat(arguments.target);
		}
		if (Len(arguments.event) > 0) {
			path = ListAppend(path, UrlEncodedFormat(arguments.event), "/");
		}

		var queryString = "";
		if (StructKeyExists(arguments, "parameters") && !StructIsEmpty(arguments.parameters)) {
			for (var name in arguments.parameters) {
				queryString = ListAppend(queryString, name & "=" & UrlEncodedFormat(arguments.parameters[name]), "&");
			}
			queryString = "?" & queryString;
		}

		return "/index.cfm" & path & queryString;
	}

	public struct function collectParameters() {

		var parameters = StructCopy(url);
		StructAppend(parameters, form, false);

		if (Len(cgi.path_info) > 1) {
			var pathInfo = RemoveChars(cgi.path_info, 1, 1); // remove the leading slash

			if (ArrayFind(getRestPaths(), function (path) {
				return Left(cgi.path_info, Len(arguments.path)) == arguments.path;
			}) > 0) {
				// REST request
				parameters.target = pathInfo;
				parameters.event = LCase(cgi.request_method);
			} else {
				var partCount = ListLen(pathInfo, "/");
				if (partCount > 1) {
					// the event is the last part, the first parts are the target
					parameters.target = ListDeleteAt(pathInfo, partCount, "/");
					parameters.event = ListLast(pathInfo, "/");
				} else {
					parameters.target = pathInfo;
					// event will revert to default
				}
			}
		}

		return parameters;
	}

}