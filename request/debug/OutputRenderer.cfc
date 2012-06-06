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

	<cfscript>
	public string function render(required array messages) {

		variables.index = 1;
		variables.messages = arguments.messages;

		// loop through the messages and reconstruct the task hierarchy
		// some tasks can contain children, but the messages array doesn't have this hierarchy
		var result = []; // resulting messages array with hierarchy
		while (variables.index <= ArrayLen(variables.messages)) {
			construct(result);
			variables.index++;
		}
		// total duration of execution
		// the messages array can be empty if output is rendered for a terminated thread
		var duration = ArrayIsEmpty(variables.messages) ? 0 : variables.messages[ArrayLen(variables.messages)].tickcount - variables.messages[1].tickcount;

		var content = "<ul>";
		for (var child in result) {
			content &= renderMessage(child);
		}
		content &= "</ul><span class=""total duration"">#duration#</span>";

		return content;
	}

	private struct function construct(required array children) {

		var data = {};
		ArrayAppend(arguments.children, data);

		data.element = variables.messages[variables.index]; // loop until we find the corresponding item
		// only certain messages can contain children
		if (REFind("cflow\.(task|(start|before|after|end|event)tasks)", data.element.message) == 1) {
			variables.index++;
			data.children = [];
			while (variables.index <= ArrayLen(variables.messages)) {
				if (structEquals(variables.messages[variables.index], data.element)) {
					break;
				}
				construct(data.children);
				variables.index++;
			}
			// task duration
			// when debug is rendered when an exception is thrown, the array is not complete so we cannot assume that the element exists
			if (ArrayLen(variables.messages) >= variables.index) {
				data.duration = variables.messages[variables.index].tickcount - data.element.tickcount;
			}
		}

		return data;
	}

	/**
	 * Returns true if the two structs contain the same keys with the same values.
	 **/
	private boolean function structEquals(required struct struct1, required struct struct2) {

		var result = true;
		for (var key in arguments.struct1) {
			// ignore tickcount
			if (key != "tickcount") {
				if (StructKeyExists(arguments.struct2, key)) {
					if (IsSimpleValue(arguments.struct1[key])) {
						result = arguments.struct1[key] == arguments.struct2[key];
					} else {
						// we expect this to be a struct
						result = structEquals(arguments.struct1[key], arguments.struct2[key]);
					}
				} else {
					result = false;
				}

				if (!result) {
					break;
				}
			}
		}

		return result;
	}
	</cfscript>

	<cffunction name="renderMessage" access="private" output="false" returntype="string">
		<cfargument name="data" type="struct" required="true">

		<cfset var child = "">
		<cfset var content = "">
		<cfset var message = data.element.message>
		<cfif StructKeyExists(data.element, "metadata")>
			<cfset var metadata = data.element.metadata>
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
						<cfcase value="cflow.eventcanceled">Event #data.element.target#.#data.element.event# canceled</cfcase>
						<cfcase value="cflow.redirect">Redirect to <a href="#metadata.url#">#metadata.url#</a></cfcase>
						<cfcase value="cflow.aborted">Request aborted</cfcase>
						<cfcase value="cflow.task">
							<cfswitch expression="#metadata.type#">
								<cfcase value="invoke">Invoke #metadata.controllerName#.#metadata.methodName#</cfcase>
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
						<span class="duration">#data.duration#</span>
					</cfif>
				</div>
				<cfset dumpMetadata = dumpMetadata and StructKeyExists(local, "metadata")>
				<cfset renderChildren = StructKeyExists(data, "children") and not ArrayIsEmpty(data.children)>
				<cfif dumpMetadata or renderChildren or renderException or renderThreadTasks>
					<div class="data">
						<cfif renderChildren>
							<cfset grandchildren = 0><!--- count children of children, so that we can report back if a dispatch task didn't have any tasks (children are phase, so we need the grandchildren) --->
							<ul>
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
						<cfif renderThreadTasks>
							<!--- create a new renderer and let it render the messages from the thread --->
							#new OutputRenderer().render(metadata.messages)#
						</cfif>
					</div>
				</cfif>
			</li>
			</cfoutput>
		</cfsavecontent>

		<cfreturn content>
	</cffunction>

</cfcomponent>