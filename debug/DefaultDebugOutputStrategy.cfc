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

<cfcomponent displayname="DefaultOutputStrategy" implements="DebugOutputStrategy" output="false">

	<cffunction name="render" access="public" output="false" returntype="string">
		<cfargument name="messages" type="array" required="true">

		<cfsavecontent variable="local.content">
			<cfoutput>
			<ol>
				<!--- some time may have been spent before the actual event handling begins --->
				<li class="initiation">
					<div class="message">
						Initiation
						<span class="time">#arguments.messages[1].elapsed#</span>
					</div>
				</li>
				<cfloop array="#arguments.messages#" index="local.child">
					#renderMessage(local.child)#
				</cfloop>
			</ol>
			<cfif StructKeyExists(arguments.messages[ArrayLen(arguments.messages)], "time")>
				<!--- for still running threads, the time attribute may not exist --->
				<span class="total time">#arguments.messages[ArrayLen(arguments.messages)].time#</span>
			</cfif>
			</cfoutput>
		</cfsavecontent>

		<cfreturn local.content>
	</cffunction>

	<cffunction name="renderMessage" access="private" output="false" returntype="string">
		<cfargument name="data" type="struct" required="true">

		<cfset var child = "">
		<cfset var content = "">
		<cfset var message = arguments.data.message>
		<cfif StructKeyExists(arguments.data, "metadata")>
			<cfset var metadata = arguments.data.metadata>
		</cfif>

		<cfset var renderChildren = false>
		<cfset var renderException = false>
		<cfset var renderThreadTasks = false>
		<cfset var dumpMetadata = false>
		<cfset var eventTasks = false>

		<cfset className = "">
		<cfif ListFirst(message, ".") eq "cflow">
			<cfset className = ListRest(message, ".")>
			<cfif message eq "cflow.task">
				<cfset className &= " " & metadata.type>
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
						<cfcase value="cflow.eventtasks">
							Event #arguments.data.target#.#arguments.data.event#
							<cfset eventTasks = true>
						</cfcase>
						<cfcase value="cflow.eventcanceled">Event #arguments.data.target#.#arguments.data.event# canceled</cfcase>
						<cfcase value="cflow.redirect">Redirect to <a href="#metadata.location#">#metadata.location#</a></cfcase>
						<cfcase value="cflow.aborted">Aborted</cfcase>
						<cfcase value="cflow.dispatch">Dispatch #metadata.targetName#.#metadata.eventType#</cfcase><!--- programmatic event dispatch --->
						<cfcase value="cflow.task">
							<cfswitch expression="#metadata.type#">
								<cfcase value="invoke">Invoke #metadata.controllerName#.#metadata.handlerName#</cfcase>
								<cfcase value="dispatch">
									Dispatch #metadata.targetName#.#metadata.eventType#
									<!--- get the event that was actually dispatched --->
									<cfset dispatchedEvent = "#metadata.dispatchTargetName#.#metadata.dispatchEventType#">
									<cfif "#metadata.targetName#.#metadata.eventType#" neq dispatchedEvent>
										[#dispatchedEvent#]
									</cfif>
								</cfcase>
								<cfcase value="render">Render #metadata.view#</cfcase>
								<cfcase value="if">If #metadata.condition#</cfcase>
								<cfcase value="else">Else<cfif Len(metadata.condition) gt 0> if #metadata.condition#</cfif></cfcase>
								<cfcase value="set">
									<cfif not metadata.exists or metadata.overwrite>
										Set #metadata.name# = #metadata.expression#
										<cfif StructKeyExists(metadata, "value") and metadata.expression neq metadata.value>
											<!--- evaluated expression; this may not exist if the expression is the cause of an exception --->
											[#metadata.value#]
										</cfif>
									<cfelse>
										(Set #metadata.name# = #metadata.expression#)
									</cfif>
								</cfcase>
								<cfcase value="thread">
									<cfswitch expression="#metadata.action#">
										<cfcase value="run">
											Run thread #metadata.name#
											<cfif metadata.priority neq "normal">with #LCase(metadata.priority)# priority</cfif>
										</cfcase>
										<cfcase value="terminate">
											Terminate thread #metadata.name#
										</cfcase>
										<cfcase value="join">
											Join thread<cfif ListLen(metadata.name) gt 1>s</cfif> #Replace(metadata.name, ",", ", ", "all")#
											<cfif metadata.timeout gt 0>within #metadata.timeout# ms</cfif>
										</cfcase>
										<cfcase value="sleep">
											Sleep #metadata.duration# ms
										</cfcase>
									</cfswitch>
								</cfcase>
								<cfcase value="abort">Abort</cfcase>
								<cfcase value="cancel">Cancel event</cfcase>
							</cfswitch>
						</cfcase>
						<cfcase value="cflow.joinedthread">
							<!--- task information regarding a joined thread --->
							Thread #metadata.name#
							<cfif metadata.status neq "completed">(#LCase(metadata.status)#)</cfif>
							<cfset renderThreadTasks = true>
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
						<span class="time">#data.duration#</span>
					<cfelse>
						<span class="time">#data.elapsed#</span>
					</cfif>
				</div>
				<cfset dumpMetadata = dumpMetadata and StructKeyExists(local, "metadata")>
				<cfset renderChildren = StructKeyExists(data, "children") and not ArrayIsEmpty(data.children)>

				<cfif eventTasks or dumpMetadata or renderChildren or renderException or renderThreadTasks>
					<div class="data">
						<cfif eventTasks and not renderChildren>
							<ol>
								<li class="eventwithouttasks"><div class="message">Event without tasks</div></li>
							</ol>
						</cfif>
						<cfif renderChildren>
							<ol>
								<cfloop array="#data.children#" index="child">
									#renderMessage(child)#
								</cfloop>
							</ol>
						</cfif>
						<cfif renderException>
							<cfset var exception = metadata.exception>
							<h2>#exception.type#: #HTMLEditFormat(exception.message)#</h2>
							<p><strong>#exception.detail#</strong></p>

							<!--- stack trace --->
							<cfset var tagContext = exception.tagContext>
							<cfif not ArrayIsEmpty(tagContext)>
								<cfset var i = 0>
								<p><strong>#tagContext[1].template#: line #tagContext[1].line#</strong></p>
								<code>#getCodeSnippet(tagContext[1])#</code>
								<ol>
									<cfloop from="2" to="#ArrayLen(tagContext)#" index="i">
									<li>
										<p>#tagContext[i].template#: line #tagContext[i].line#</p>
										<code class="hidden">#getCodeSnippet(tagContext[i])#</code>
									</li>
									</cfloop>
								</ol>
							</cfif>
							<div class="stacktrace">
								<strong>Java stack trace</strong>
								<pre class="hidden">#exception.stacktrace#</pre>
							</div>
						</cfif>
						<cfif dumpMetadata>
							<cfdump var="#metadata#">
						</cfif>
						<cfif renderThreadTasks>
							<!--- render the messages from the thread --->
							#render(metadata.messages)#
						</cfif>
					</div>
				</cfif>
			</li>
			</cfoutput>
		</cfsavecontent>

		<cfreturn content>
	</cffunction>

	<cffunction name="generate" access="public" returntype="string">
		<cfargument name="messages" type="array" required="true">

		<cfset var debugoutput = render(arguments.messages)>

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
					margin: 0;
					padding: 0 12px;
				}

				#cflow ol > li {
					font-family: Verdana, sans-serif;
					font-size: 9pt;
					padding: 0px;
					border: 2px dashed transparent;
					list-style-type: none;
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

				#cflow .task > .message,
				#cflow .dispatch > .message {
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

				#cflow .exception .stacktrace {
					margin-top: 12px;
					cursor: pointer;
				}

				#cflow .exception .stacktrace > pre {
					font-family: inherit;
				}

				#cflow .hidden {
					display: none !important;
				}
			</style>

			<cfoutput>
			<div id="cflow">
				<h1>CFlow debugging information</h1>
				#debugoutput#
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

					Array.prototype.forEach.call(document.querySelectorAll("#cflow li, #cflow li.exception .stacktrace"), function (node) {
						node.addEventListener("click", click);
					});
				})();
			</script>
		</cfsavecontent>

		<cfreturn debugoutput>
	</cffunction>

	<cfscript>
	/**
	 * Returns the code snippet of the tag context in the exception.
	 **/
	private string function getCodeSnippet(required struct tagContext) {

		var result = "";

		var file = FileOpen(arguments.tagContext.template, "read");
		var lineNumber = arguments.tagContext.line;

		var startLine = Max(arguments.tagContext.line - 2, 0);
		var endLine = arguments.tagContext.line + 2;

		for (var i = 1; i < startLine; i++) {
			FileReadLine(file);
		}

		for (var i = startLine; i <= endLine && !FileIsEOF(file); i++) {
			var line = i & ": " & HTMLEditFormat(FileReadLine(file));
			if (i == lineNumber) {
				line = "<strong>" & line & "</strong>";
			}
			result &= line & "<br>";
		}

		FileClose(file);

		return result;
	}
	</cfscript>

</cfcomponent>