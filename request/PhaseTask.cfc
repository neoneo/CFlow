/**
 * A PhaseTask is a task that contains tasks for a particular phase.
 **/
component PhaseTask extends="ComplexTask" {

	public boolean function run(required Event event) {
		return runSubtasks(arguments.event);
	}

}