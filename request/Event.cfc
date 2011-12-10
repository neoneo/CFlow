component {

	variables.cancelled = false;

	public void function init(required Controller target, required string type, struct properties = {}) {

		variables.target = arguments.target;
		variables.type = arguments.type;

		setProperties(arguments.properties);
		// make the type and the target available as public properties
		// this also means they can be set, so the actual values of these properties cannot be trusted
		// core components therefore have to use the package methods to get the actual values of these properties
		this.target = arguments.target;
		this.type = arguments.type;
	}

	public Controller function getTarget() {
		return variables.target;
	}

	public string function getType() {
		return variables.type;
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

}