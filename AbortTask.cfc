component AbortTask implements="Task" {

	public boolean function run(required Event event) {

		arguments.event.abort();

		return true;
	}

	public string function getType() {
		return "abort";
	}

}