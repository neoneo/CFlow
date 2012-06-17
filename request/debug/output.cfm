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

<cfsavecontent variable="content">
	<cfset response.write()>
</cfsavecontent>
<cfsavecontent variable="debugoutput">
<style type="text/css">
	#cflow {
		font-family: Verdana, sans-serif;
		font-size: 9pt;
		color: #000;
		background-color: white;
	}

	#cflow > h1 {
		font-weight: bold;
		font-size: 12pt;
		padding: 2px 16px;
	}

	#cflow ol {
		list-style-type: none;
		margin: 0;
		padding: 0 12px;
	}

	#cflow ol > li {
		padding: 0px;
		border: 2px dashed transparent;
	}

	#cflow ol > li.hover {
		border-color: #f00;
	}

	#cflow .time {
		font-weight: bold;
		float: right;
	}

	#cflow .total {
		padding: 0 16px;
	}

	#cflow .message, #cflow .data {
		border: 1px solid #000;
		padding: 2px;
		overflow: hidden;
	}

	#cflow .message {
		overflow: hidden;
		background-color: #ffb200;
	}

	#cflow .initiation > .message {
		background-color: transparent;
		font-weight: bold;
		color: #999;
		border-color: #999;
	}

	#cflow .data {
		margin-top: 1px;
	}

	#cflow .phase > .message {
		background-color: #9c3;
		font-weight: bold;
	}

	#cflow .phase > .data {
		background-color: #cf3;
	}

	#cflow .task > .message {
		background-color: #99f;
	}

	#cflow .joinedthread > .message {
		background-color: #66c;
	}

	#cflow .redirect a {
		text-decoration: underline;
		color: #fff;
	}

	#cflow .redirect > .message {
		background-color: #666;
		color: #fff;
	}

	#cflow .task > .data {
		background-color: #ccf;
	}

	#cflow .eventcanceled > .message,
	#cflow .eventwithouttasks > .message,
	#cflow .aborted > .message {
		background-color: #f60;
	}

	#cflow .exception > .message {
		background-color: #dc322f;
		font-weight: bold;
		color: #fff;
	}

	#cflow .exception > .data {
		background-color: #fc0;
	}

	#cflow .exception h2 {
		font-size: 11pt;
	}

	#cflow .exception ol {
		padding: 0px;
		margin-top: 12px;
	}

	#cflow .exception li {
		border-width: 0;
	}

	#cflow .exception li > p {
		margin: 0;
		cursor: pointer;
	}

	#cflow .exception li code {
		margin: 12px 0 12px 12px;
		display: block;
	}

	#cflow .hidden {
		display: none !important;
	}
</style>

<cfoutput>
<div id="cflow">
	<h1>CFlow debugging information</h1>
	#_debugoutput#
</div>
</cfoutput>
<script>
	(function () {
		function mouseover(e) {
			e.currentTarget.classList.add("hover");
			e.stopPropagation();
		};

		function mouseout(e) {
			e.currentTarget.classList.remove("hover");
		};

		function click(e) {
			var toggleNode = e.currentTarget.children[1];
			if (toggleNode) {
				toggleNode.classList.toggle("hidden");
			}
			e.stopPropagation();
		}

		Array.prototype.forEach.call(document.querySelectorAll("#cflow > ol > li, #cflow li:not(.exception) > .data > ol > li"), function (node) {
			node.addEventListener("mouseover", mouseover);
			node.addEventListener("mouseout", mouseout);
		});

		Array.prototype.forEach.call(document.querySelectorAll("#cflow li"), function (node) {
			node.addEventListener("click", click);
		});
	})();
</script>
</cfsavecontent>
<cfoutput>
	<cfswitch expression="#response.getType()#">
		<cfcase value="HTML">
			<!--- put the debugoutput inside the body if applicable --->
			<cfif content contains "</body>">
				#Replace(content, "</body>", debugoutput & "</body>")#
			<cfelse>
				#content#
				#debugoutput#
			</cfif>
		</cfcase>
		<cfcase value="JSON">
			<!--- if the data is a struct, put the debugoutput on it --->
			<!--- otherwise ignore it --->
			<cfset data = DeserializeJSON(content)>
			<cfif IsStruct(data)>
				<cfset data["_debugoutput"] = ReplaceList(debugoutput, "#Chr(9)#,#Chr(10)#,#Chr(13)#", "")>
			</cfif>
			<cfset response.append(data)>
		</cfcase>
		<cfdefaultcase>
			#content#
			#debugoutput#
		</cfdefaultcase>
	</cfswitch>
</cfoutput>