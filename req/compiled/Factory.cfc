component Factory {

	public void function init(required Context context) {
		variables.context = arguments.context;
	}

	public Event function createEvent(required struct parameters) {
		return new Event(arguments.parameters);
	}

	public Response function createResponse() {
		return new Response();
	}

}