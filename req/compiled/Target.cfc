<cfcomponent displayname="Target" output="false">

	<cfscript>
	include "/cflow/static/invoke.cfm";

	public void function init(required Context context, required string name) {
		variables.context = arguments.context;
		variables.name = arguments.name;
	}

	public void function handleEvent(required string eventType, required Event event, required Response response) {

		start(arguments.event, arguments.response);

		var canceled = arguments.event.isCanceled();
		var aborted = arguments.event.isAborted();
		if (!canceled && !aborted) {
			invokeMethod(this, arguments.eventType, {event = arguments.event, response = arguments.response});
		}

		canceled = arguments.event.isCanceled();
		aborted = arguments.event.isAborted();
		if (!aborted) {
			if (canceled) {
				arguments.event.reset();
			}
			end (arguments.event, arguments.response);
		}

	}

	public void function onMissingMethod(required string missingMethodName, required struct missingMethodArguments) {

		// an event is dispatched on this target, but the target is not listening
		before(argumentCollection = arguments.missingMethodArguments);

		var event = arguments.missingMethodArguments.event;
		if (!event.isCanceled() && !event.isAborted()) {
			// first check if we can dispatch the undefined event on this target
			var undefinedEvent = variables.context.getUndefinedEvent();
			if (arguments.missingMethodName != undefinedEvent) {
				// dispatch the undefined event on this target
				invokeMethod(this, undefinedEvent, arguments.missingMethodArguments);
			} else {
				// we tried the undefined event with no luck, dispatch the event to the undefined target
				var undefinedTarget = variables.context.getUndefinedTarget();
				if (variables.name != undefinedTarget) {
					invokeMethod(variables.context.getTarget(undefinedTarget), undefinedEvent, arguments.missingMethodArguments);
				}
			}
		}

		if (!event.isCanceled() && !event.isAborted()) {
			after(argumentCollection = arguments.missingMethodArguments);
		}

	}

	private void function start() {}

	private void function before() {}

	private void function after() {}

	private void function end() {}

	private Context function getContext() {
		return variables.context;
	}

	</cfscript>

	<cffunction name="render" access="private" output="false" returntype="void">
		<cfargument name="view" type="string" required="true">
		<cfargument name="data" type="struct" required="true">
		<cfargument name="response" type="Response" required="true">
		<cfargument name="contentKey" type="string" required="true">

		<!--- set the content key, so that response.append() calls without a key argument will write to this view --->
		<cfset arguments.response.setContentKey(arguments.contentKey)>

		<cfsavecontent variable="local.content">
			<cfmodule template="/cflow/req/render.cfm" view="#arguments.view#.cfm" response="#arguments.response#" data="#arguments.data#" requeststrategy="#variables.requestStrategy#">
		</cfsavecontent>

		<!--- depending on the content key is not thread safe, so we pass the key explicitly --->
		<cfset response.append(local.content, arguments.contentKey)>

	</cffunction>

</cfcomponent>