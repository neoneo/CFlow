component EventTask extends="ComplexTask" {

	public boolean function process(required Event event) {
		return processSubtasks(arguments.event);
	}

}