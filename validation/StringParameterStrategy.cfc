/**
 * Abstracts access to parameter values.
 * The setValue() method accepts any string expression, and a boolean that indicates whether to evaluate that expression.
 * The getValue() method accepts a data struct that provides context for the expression (if evaluated), and returns the result.
 * If no evaluation should occur, this component just stores and returns the expression as is.
 **/
component StringParameterStrategy {

	public void function setValue(required string expression, boolean evaluate = false) {

		variables.evaluate = arguments.evaluate;
		if (arguments.evaluate) {
			// interpret all alphanumeric strings as variable names, present in the arguments.data struct in getValue()
			variables.expression = Trim(REReplaceNoCase(" " & arguments.expression & " ", " ([a-z_]+[a-z0-9_]*) ", " arguments.data.\1 ", "all"));
		} else {
			variables.expression = arguments.expression;
		}

	}

	public string function getValue(required struct data) {

		var value = JavaCast("null", 0);

		if (variables.evaluate) {
			value = Evaluate(variables.expression);
		} else {
			value = variables.expression;
		}

		return value;
	}

}