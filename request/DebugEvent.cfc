component DebugEvent extends="Event" {

	public void function init(required string target, required string type, required struct properties, required Response response) {

		this._messages = [];
		super.init(arguments.target, arguments.type, arguments.properties, arguments.response);

	}

	public void function cancel() {

		record("eventCanceled");
		super.cancel();

	}

	public void function record(required string message, struct metadata = {}) {

		ArrayAppend(this._messages, {
			message = arguments.message,
			metadata = arguments.metadata,
			target = getTarget(),
			event = getType(),
			tickcount = GetTickCount()
		});

	}

	public Event function clone() {
		return new DebugEvent(getTarget(), getType(), getProperties(), getResponse());
	}

}