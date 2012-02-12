component RangeRule implements="Rule" accessors="true" {

	property name="field" type="string" required="true";
	property name="from" type="numeric" required="true";
	property name="to" type="numeric" required="true";

	public boolean function test(required struct data) {
		return arguments.data[getField()] >= getFrom() && arguments.data[getField()] <= getTo();
	}

}