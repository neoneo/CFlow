component EventTask extends="ComplexTask" {

	public boolean function run(required Event event) {
		return runSubtasks(arguments.event);
	}

}