component Event {

	variables.canceled = false;

	public void function init(required string target, required string type, required struct properties, required Response response) {

		variables.target = arguments.target;
		variables.type = arguments.type;
		variables.response = arguments.response;

		setProperties(arguments.properties);

	}

	public string function getTarget() {
		return variables.target;
	}

	public string function getType() {
		return variables.type;
	}

	public void function cancel() {
		variables.canceled = true;
	}

	public boolean function isCanceled() {
		return variables.canceled;
	}

	public struct function getProperties() {

		var properties = {};
		for (var property in this) {
			if (!IsCustomFunction(this[property])) {
				properties[property] = this[property];
			}
		}

		return properties;
	}

	public void function setProperties(required struct properties) {

		for (var property in arguments.properties) {
			if (!StructKeyExists(this, property) || !IsCustomFunction(this[property])) {
				this[property] = arguments.properties[property];
			}
		}

	}

	/**
	* Returns a copy of the event, with its canceled flag reset.
	**/
	public Event function clone() {
		return new Event(getTarget(), getType(), getProperties(), getResponse());
	}

	package Response function getResponse() {
		return variables.response;
	}

}