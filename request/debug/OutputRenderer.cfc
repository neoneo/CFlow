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

<cfcomponent displayname="OutputRenderer" output="false">

	<cffunction name="render" access="public" output="false" returntype="string">
		<cfargument name="messages" type="array" required="true">

		<cfsavecontent variable="local.content">
			<cfoutput>
			<ol>
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
		<cfset var dispatchTask = false>

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
						<cfcase value="cflow.eventtasks">Event</cfcase>
						<cfcase value="cflow.eventcanceled">Event #arguments.data.target#.#arguments.data.event# canceled</cfcase>
						<cfcase value="cflow.redirect">Redirect to <a href="#metadata.url#">#metadata.url#</a></cfcase>
						<cfcase value="cflow.aborted">Request aborted</cfcase>
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
									<cfset dispatchTask = true>
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
				<cfif dumpMetadata or renderChildren or renderException or renderThreadTasks>
					<div class="data">
						<cfif renderChildren>
							<cfset grandchildren = 0><!--- count children of children, so that we can report back if a dispatch task didn't have any tasks (children are phase, so we need the grandchildren) --->
							<ol>
							<cfloop array="#data.children#" index="child">
								#renderMessage(child)#
								<cfif dispatchTask && StructKeyExists(child, "children")>
									<!--- count the grandchildren --->
									<cfset grandchildren += ArrayLen(child.children)>
								</cfif>
							</cfloop>
							<cfif dispatchTask and grandchildren eq 0>
								<li class="eventwithouttasks"><div class="message">Event without tasks</div></li>
							</cfif>
							</ol>
						</cfif>
						<cfif renderException>
							<cfset var exception = metadata.exception>
							<h2>#exception.type#: #HTMLEditFormat(exception.message)#</h2>
							<p><strong>#exception.detail#</strong></p>

							<!--- stack trace --->
							<cfset var tagContext = exception.tagContext>
							<cfset var i = 0>
							<p><strong>#tagContext[1].template#: line #tagContext[1].line#</strong></p>
							<code>#tagContext[1].codePrintHTML#</code>
							<ol>
								<cfloop from="2" to="#ArrayLen(tagContext)#" index="i">
								<li>
									<p>#tagContext[i].template#: line #tagContext[i].line#</p>
									<code class="hidden">#tagContext[i].codePrintHTML#</code>
								</li>
								</cfloop>
							</ol>
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

</cfcomponent>