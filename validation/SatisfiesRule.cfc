component SatisfiesRule implements="Rule" {

	public void function setParameter(required string expression) {

		// replace all ColdFusion operators by its script counterparts
		var result = ReplaceList(result," eq , lt , lte , gt , gte , neq , not , and , or , mod "," == , < , <= , > , >= , != , ! , && , || , % ");
		// interpret all remaining alphanumeric terms as a field name (which will be available in arguments.data)
		result = REReplaceNoCase(" " & result & " ", " ([a-z_]+[a-z0-9_]*) ", " arguments.data.\1 ", "all");
		// remove excess whitespace
		result = REReplace(Trim(result), "[\s]+", " ", "all");

		variables.expression = result;

	}

	public boolean function test(required struct data) {
		return Evaluate(variables.expression);
	}

}