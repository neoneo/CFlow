component Factory {

	public void function init(required Context context) {
		variables.context = arguments.context;
	}

	public InvokeTask function createInvokeTask(required string controllerName, required string methodName) {
		return new InvokeTask(getController(arguments.controllerName), arguments.methodName);
	}

	public DispatchTask function createDispatchTask(required string targetName, required string eventType, boolean cancelFailed = true) {
		return new DispatchTask(variables.context, arguments.targetName, arguments.eventType, arguments.cancelFailed);
	}

	public RenderTask function createRenderTask(required string view) {
		return new RenderTask(arguments.view, variables.context.getViewMapping(), variables.context.getRequestStrategy());
	}

	/**
	 * Creates a RedirectTask.
	 *
	 * @param	{String}	type		the redirect type: url or event
	 * @param	{Struct}	parameters	the parameters specific to the type of redirect (see below)
	 * @param	{Boolean}	permanent	whether the redirect is permanent or not [false]
	 *
	 * Redirect types:
	 * url		The parameters struct should have a url key that contains the explicit url to redirect to
	 * event	The parameters struct should have target and event keys, and may have additional keys that are used as url parameters
	 **/
	public RedirectTask function createRedirectTask(required string type, required struct parameters, boolean permanent = false) {
		return new RedirectTask(arguments.type, arguments.parameters, arguments.permanent, variables.context.getRequestStrategy());
	}

	public IfTask function createIfTask(required string condition) {
		return new IfTask(arguments.condition);
	}

	public ElseTask function createElseTask(string condition = "") {
		return new ElseTask(arguments.condition);
	}

	public SetTask function createSetTask(required string name, required string expression, boolean overwrite = true) {
		return new SetTask(arguments.name, arguments.expression, arguments.overwrite);
	}

	public PhaseTask function createPhaseTask() {
		return new PhaseTask();
	}

	public Event function createEvent(required struct parameters, required Response response) {
		return new Event(arguments.parameters, arguments.response);
	}

	public Response function createResponse() {
		return new Response();
	}

}