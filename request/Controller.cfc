component Controller {

	private boolean function dispatchEvent(required string eventType, required Event event) {

		var targetName = arguments.event.getTarget();
		var properties = arguments.event.getProperties();

		return arguments.event.getProcessor().processEvent(targetName, arguments.eventType, properties);
	}

}
