component extends="TaskNode" {

	public void function accept(required Visitor visitor) {
		arguments.visitor.visitEndNode(this)
	}

}