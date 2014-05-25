component {

	variables._children = []

	public void function add(required Node node) {
		variables._children.append(arguments.node)
	}

	public Node[] function children() {
		return variables._children
	}

	public Boolean function hasChildren() {
		return !variables._children.isEmpty()
	}

	public void function accept(required Visitor visitor) {
		Throw("Not implemented", "NoSuchMethodException")
	}

}