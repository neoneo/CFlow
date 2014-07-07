component extends="Node" {

	public void function accept(required Visitor visitor) {
		arguments.visitor.visitTargetsNode(this)
	}

}