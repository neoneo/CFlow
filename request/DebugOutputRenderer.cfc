<cfcomponent displayname="DebugOutputRenderer" output="false">

	<cffunction name="render" access="public" output="false" returntype="string">
		<cfargument name="messages" type="array" required="true">

		<cfset variables.index = 1>
		<cfset variables.messages = arguments.messages>

		<!--- loop through the messages and reconstruct the task hierarchy --->
		<!--- some tasks can contain children, but the messages array doesn't have this hierarchy --->
		<cfset var result = []><!--- resulting messages array with hierarchy --->
		<cfloop condition="variables.index lte ArrayLen(variables.messages)">
			<cfset construct(result)>
			<cfset variables.index++>
		</cfloop>
		<!--- total duration of execution --->
		<cfset var duration = variables.messages[ArrayLen(variables.messages)].tickcount - variables.messages[1].tickcount>

		<cfoutput>
		<cfsavecontent variable="local.content">
		<h1>CFlow debugging information</h1>
		<ul>
		<cfloop array="#result#" index="child">
			#renderMessage(child)#
		</cfloop>
		</ul>
		<span class="total duration">#duration#</span>
		</cfsavecontent>
		</cfoutput>

		<cfreturn local.content>
	</cffunction>

	<cffunction name="construct" access="private" output="false" returntype="struct" hint="Constructs the task hierarchy from the messages array.">
		<cfargument name="children" type="array" required="true" hint="The array wherein to collect task data.">

		<cfset var data = {}>
		<cfset ArrayAppend(arguments.children, data)>

		<cfset data.element = variables.messages[variables.index]><!--- we loop until we find the corresponding item --->
		<!--- only certain messages can contain children --->
		<cfif REFind("cflow\.(task|(start|before|after|end|event)tasks)", data.element.message) eq 1>
			<cfset variables.index++>
			<cfset data.children = []>
			<cfloop condition="variables.index lte ArrayLen(variables.messages)">
				<cfif structEquals(variables.messages[variables.index], data.element)>
					<cfbreak>
				</cfif>
				<cfset construct(data.children)>
				<cfset variables.index++>
			</cfloop>
			<!--- task duration --->
			<!--- when debug is rendered when an exception is thrown, the array is not complete so we cannot assume that the element exists --->
			<cfif ArrayLen(variables.messages) gte variables.index>
				<cfset data.duration = variables.messages[variables.index].tickcount - data.element.tickcount>
			</cfif>
		</cfif>

		<cfreturn data>
	</cffunction>

	<cffunction name="structEquals" access="private" output="false" returntype="boolean">
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
								<cfcase value="EvaluateTask">Evaluate #metadata.condition#</cfcase>
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
					</div>
				</cfif>
			</li>
			</cfoutput>
		</cfsavecontent>

		<cfreturn content>
	</cffunction>

</cfcomponent>