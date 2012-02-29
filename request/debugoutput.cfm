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

<cfsilent>
	<cffunction name="construct" output="false" returntype="struct" hint="Constructs the task hierarchy from the messages array.">
		<cfargument name="children" type="array" required="true" hint="The array wherein to collect task data.">

		<!--- the messages and index variables are present in the template scope, so they are not local --->

		<cfset var data = {}>
		<cfset ArrayAppend(arguments.children, data)>

		<cfset data.element = messages[index]><!--- we loop until we find the corresponding item --->
		<!--- only certain messages can contain children --->
		<cfif REFind("cflow\.(task|(start|before|after|end|event)tasks)", data.element.message) eq 1>
			<cfset index++>
			<cfset data.children = []>
			<cfloop condition="index lte ArrayLen(messages)">
				<cfif structEquals(messages[index], data.element)>
					<cfbreak>
				</cfif>
				<cfset construct(data.children)>
				<cfset index++>
			</cfloop>
			<!--- task duration --->
			<!--- when debug is rendered when an exception is thrown, the array is not complete so we cannot assume that the element exists --->
			<cfif ArrayLen(messages) gte index>
				<cfset data.duration = messages[index].tickcount - data.element.tickcount>
			</cfif>
		</cfif>

		<cfreturn data>
	</cffunction>

	<cffunction name="structEquals" output="false" returntype="boolean">
		<cfargument name="struct1" type="struct" required="true">
		<cfargument name="struct2" type="struct" required="true">

		<cfset var key = "">
		<cfset var isEqual = true>
		<cfloop collection="#arguments.struct1#" item="key">
			<!--- ignore tickcount --->
			<cfif key neq "tickcount">
				<cfif StructKeyExists(arguments.struct2, key)>
					<cfif IsSimpleValue(arguments.struct1[key])>
						<cfset isEqual = arguments.struct1[key] eq arguments.struct2[key]>
					<cfelse>
						<!--- we expect this to be a struct --->
						<cfset isEqual = structEquals(arguments.struct1[key], arguments.struct2[key])>
					</cfif>
				<cfelse>
					<cfset isEqual = false>
				</cfif>

				<cfif not isEqual>
					<cfbreak>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn isEqual>
	</cffunction>

	<cffunction name="render" output="false" returntype="string">
		<cfargument name="data" type="struct" required="true">

		<cfset var child = "">
		<cfset var content = "">
		<cfset var message = data.element.message>
		<cfif StructKeyExists(data.element, "metadata")>
			<cfset var metadata = data.element.metadata>
		</cfif>

		<cfset var renderChildren = false>
		<cfset var renderException = false>
		<cfset var dumpMetadata = false>
		<cfset var dispatchTask = false>

		<cfset className = "">
		<cfif ListFirst(message, ".") eq "cflow">
			<cfset className = ListRest(message, ".")>
			<cfif message eq "cflow.task">
				<cfset var type = ListLast(metadata.type, ".")>
				<!--- cut off "Task" and make lower case --->
				<cfset className &= " " & LCase(Left(type, Len(type) - 4))>
			<cfelseif REFind("cflow\.(start|before|after|end|event)tasks", message) eq 1>
				<cfset className &= " phase">
			</cfif>
		<cfelse>
			<cfset className="custom">
		</cfif>

		<cfsavecontent variable="content">
			<cfoutput>
			<li class="#className#">
				<div class="message">
					<cfswitch expression="#message#">
						<cfcase value="cflow.starttasks">Start</cfcase>
						<cfcase value="cflow.beforetasks">Before</cfcase>
						<cfcase value="cflow.aftertasks">After</cfcase>
						<cfcase value="cflow.endtasks">End</cfcase>
						<cfcase value="cflow.eventtasks">Event</cfcase>
						<cfcase value="cflow.eventcanceled">Event #data.element.target#.#data.element.event# canceled</cfcase>
						<cfcase value="cflow.redirect">Redirect to <a href="#metadata.url#">#metadata.url#</a></cfcase>
						<cfcase value="cflow.aborted">Request aborted</cfcase>
						<cfcase value="cflow.task">
							<cfswitch expression="#type#">
								<cfcase value="InvokeTask">Invoke #metadata.controllerName#.#metadata.methodName#</cfcase>
								<cfcase value="DispatchTask">
									Dispatch #metadata.targetName#.#metadata.eventType#
									<cfset dispatchTask = true>
								</cfcase>
								<cfcase value="RenderTask">Render #metadata.view#</cfcase>
							</cfswitch>
						</cfcase>
						<cfcase value="cflow.exception">
							Exception
							<cfset renderException = true>
						</cfcase>
						<cfdefaultcase>
							#message#
							<!--- dump metadata if we don't know what it's about --->
							<cfset dumpMetadata = true>
						</cfdefaultcase>
					</cfswitch>
					<cfif StructKeyExists(data, "duration")>
						<span class="duration">#data.duration#</span>
					</cfif>
				</div>
				<cfset dumpMetadata = dumpMetadata and StructKeyExists(local, "metadata")>
				<cfset renderChildren = StructKeyExists(data, "children") and not ArrayIsEmpty(data.children)>
				<cfif dumpMetadata or renderChildren or renderException>
					<cfset grandchildren = 0><!--- count children of children, so that we can report back if a dispatch task didn't have any tasks (children are phase, so we need the grandchildren) --->
					<div class="data">
						<cfif renderChildren>
							<ul>
							<cfloop array="#data.children#" index="child">
								#render(child)#
								<cfif dispatchTask && StructKeyExists(child, "children")>
									<!--- count the grandchildren --->
									<cfset grandchildren += ArrayLen(child.children)>
								</cfif>
							</cfloop>
							<cfif dispatchTask and grandchildren eq 0>
								<li class="eventwithouttasks"><div class="message">Event without tasks</div></li>
							</cfif>
							</ul>
						</cfif>
						<cfif renderException>
							<cfset var exception = metadata.exception>
							<h2>#exception.type#: #exception.message#</h2>
							<p><strong>#exception.detail#</strong></p>

							<!--- stack trace --->
							<cfset var tagContext = exception.tagContext>
							<cfset var i = 0>
							<p><strong>#tagContext[1].template#: line #tagContext[1].line#</strong></p>
							<code>#tagContext[1].codePrintHTML#</code>
							<p>
								<cfloop from="2" to="#ArrayLen(tagContext)#" index="i">
								<div>#tagContext[i].template#: line #tagContext[i].line#</div>
								</cfloop>
							</p>
						</cfif>
						<cfif dumpMetadata>
							<cfdump var="#metadata#">
						</cfif>
					</div>
				</cfif>
			</li>
			</cfoutput>
		</cfsavecontent>

		<cfreturn content>
	</cffunction>

	<!--- construct the task hierarchy --->
	<cfset messages = data._messages>
	<cfset index = 1>
	<cfset result = []>
	<cfloop condition="index lte ArrayLen(messages)">
		<cfset construct(result)>
		<cfset index++>
	</cfloop>
</cfsilent>

<!--- output the results --->
<style type="text/css">
	#cflow {
		font-family: Verdana, sans-serif;
		font-size: 9pt;
		color: #000;
	}

	#cflow > h1 {
		font-weight: bold;
		font-size: 12pt;
		padding: 2px 16px;
	}

	#cflow ul {
		list-style-type: none;
		margin: 0;
		padding: 0 12px;
	}

	#cflow li {
		padding: 0px;
		border: 2px dashed transparent;
	}

	#cflow .duration {
		font-weight: bold;
		float: right;
	}

	#cflow .message, #cflow .data {
		border: 1px solid #000;
		padding: 2px;
	}

	#cflow .message {
		overflow: hidden;
		background-color: #ffb200;
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
</style>

<cfoutput>
<div id="cflow">
	<h1>CFlow debugging information</h1>
	<ul>
	<cfloop array="#result#" index="child">
		#render(child)#
	</cfloop>
	</ul>
</div>
</cfoutput>

<script>
	var cflow = {

		node: document.getElementById("cflow"),

		getActiveListItem: function (node) {
			var listItem = node;

			while (listItem.tagName.toLowerCase() !== "li" && listItem !== this.node) {
				listItem = listItem.parentNode;
			}

			if (listItem === this.node) {
				listItem = null;
			}

			return listItem;
		}

	};

	cflow.node.addEventListener("mouseover", function (e) {
		var listItem = cflow.getActiveListItem(e.target);
		if (listItem) {
			listItem.style.borderColor = "#f00";
		}
	}, false);

	cflow.node.addEventListener("mouseout", function (e) {
		var listItem = cflow.getActiveListItem(e.target);
		if (listItem) {
			listItem.style.borderColor = "";
		}
	}, false);

	cflow.node.addEventListener("click", function (e) {
		var listItem = cflow.getActiveListItem(e.target);
		if (listItem) {
			var dataDiv = listItem.children[1];
			if (dataDiv) {
				dataDiv.style.display = dataDiv.style.display === "none" ? "" : "none";
			}
		}
	}, false);

</script>
