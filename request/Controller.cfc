component {

	public void function init(required Processor processor, required string name) {
		variables.processor = arguments.processor;
		variables.name = arguments.name;
	}

	private boolean function dispatchEvent(required string eventType, Event event) {

		var properties = JavaCast("null", 0);
		if (StructKeyExists(arguments, "event")) {
			properties = arguments.event.getProperties();
		} else {
			properties = {};
		}

		// if the event is a single list item, the event target is this controller
		var eventType = arguments.eventType;
		var targetName = getName();
		if (ListLen(eventType, ".") > 1) {
			targetName = ListFirst(eventType ,".");
			eventType = ListLast(eventType ,".");
		}

		return getProcessor().processEvent(targetName, eventType, properties);
	}

	private Processor function getProcessor() {
		return variables.processor;
	}

	private string function getName() {
		return variables.name;
	}

}
