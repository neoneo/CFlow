component {

	public void function init(required Context context) {
		variables.context = arguments.context;
	}

	public Handler function createHandler(required string name) {
		return new "#arguments.name#"(getContext());
	}

	public View function createView(required string name) {
		return new "#arguments.name#"(getContext());
	}

	public Event function createEvent(required Handler target, required string eventType, struct properties = {}) {
		return new Event(arguments.target, arguments.eventType, arguments.properties);
	}

	public Processor function createProcessor() {
		return new Processor(getContext());
	}

	private Context function getContext() {
		return variables.context;
	}

}