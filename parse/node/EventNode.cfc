component extends="TaskNode" accessors="true" {

	property String type;
	property String access default="public";

	public void function accept(required Visitor visitor) {
		arguments.visitor.visitEventNode(this)
	}

}