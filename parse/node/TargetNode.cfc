component extends="Node" accessors="true" {

	property String name;
	property String defaultlistener;
	property Boolean abstract default="false";

	public void function accept(required Visitor visitor) {
		arguments.visitor.visitTargetNode(this)
	}

}