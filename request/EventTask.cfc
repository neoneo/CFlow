component EventTask extends="AbstractTask" {

	public boolean function process(required Event event) {
		return processSubtasks(arguments.event);
	}

}