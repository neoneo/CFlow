component DebugEvent extends="Event" {

	this._messages = [];

	public void function cancel() {

		logMessage("eventCanceled");
		super.cancel();

	}

	public void function logMessage(required string message, struct metadata = {}) {

		ArrayAppend(this._messages, {
			"message" = arguments.message,
			"metadata" = arguments.metadata,
			"target" = getTarget(),
			"event" = getType(),
			"tickcount" = GetTickCount()
		});

	}

	public Event function clone() {
		return new DebugEvent(getTarget(), getType(), getProperties(), getResponse());
	}

}