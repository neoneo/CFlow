/**
 * Abstracts access to parameter values.
 * The setValue() method accepts any string expression, and a boolean that indicates whether to evaluate that expression.
 * The getValue() method accepts a data struct that provides context for the expression (if evaluated), and returns the result.
 * If no evaluation should occur, this component just stores and returns the expression as is.
 **/
component Parameter {

	public void function setValue(required string expression, boolean evaluate = false) {

		variables.evaluate = arguments.evaluate;
		if (arguments.evaluate) {
			variables.expression = new cflow.util.Evaluator(arguments.expression);
		} else {
			variables.expression = arguments.expression;
		}

	}

	public any function getValue(required struct data) {

		var value = JavaCast("null", 0);

		if (variables.evaluate) {
			value = variables.expression.execute(arguments.data);
		} else {
			value = variables.expression;
		}

		return value;
	}

}