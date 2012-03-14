/**
 * Abstract implementation for rules that act on sets (arrays).
 **/
component SetRule implements="Rule" {

	public void function init(required string value, boolean evaluate = false, boolean matchCase = false) {

		variables.parameter = new SetParameter();
		variables.parameter.setValue(arguments.value, arguments.evaluate);
		variables.matchCase = arguments.matchCase;

	}

	public boolean function test(required struct data, required string fieldName) {
		Throw(type = "cflow.notimplemented", message = "Not implemented");
	}

	public string function formatParameterValue(required struct data, string mask = "") {
		return ArrayToList(getParameterValue(arguments.data), ", ");
	}

	private array function getParameterValue(required struct data) {
		return variables.parameter.getValue(arguments.data);
	}

	private array function toArray(required string value) {
		return ListToArray(arguments.value);
	}

	/**
	 * Determines whether a set is a subset of another.
	 **/
	private boolean function isSubset(required array set, required array superset) {

		var size = ArrayLen(arguments.set);

		// check if all elements in set occur in superset
		var i = 1;
		while (i <= size && isElement(arguments.set[i], arguments.superset)) {
			i++;
		}

		return i > size;
	}

	/**
	 * Determines whether the value is an element of the set.
	 **/
	private boolean function isElement(required string value, required array set) {

		var result = false;

		if (variables.matchCase) {
			result = ArrayFind(arguments.set, arguments.value) > 0;
		} else {
			result = ArrayFindNoCase(arguments.set, arguments.value) > 0;
		}

		return result;
	}

}