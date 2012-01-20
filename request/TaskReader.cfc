component TaskReader {

	public struct function read(required string path) {
		variables.tasks = {}; // lists of tasks per target
		variables.defaultControllers = {}; // default controllers per target

		var path = ExpandPath(arguments.path);
		var list = DirectoryList(path, false, "name", "*.xml");

		for (var fileName in list) {
			readFile(path & "/" & fileName);
		}

		compileIncludes();
		setTaskDefaults();

		return variables.tasks;
	}

	public void function register(required Context context) {

		var phases = ["start", "end", "before", "after"];
		// variables.tasks is a struct where each key is a target name
		for (var name in variables.tasks) {

			var tasks = variables.tasks[name];
			// tasks contains all the tasks for this target, stored by phase and by event
			// first create tasks for all phases
			for (var phase in phases) {
				// always create the task, even if it remains empty, because otherwise the task is created for each request later
				var eventTask = createTask(arguments.context);
				if (StructKeyExists(tasks, phase)) {
					for (var task in tasks[phase]) {
						eventTask.addSubtask(createTask(arguments.context, task));
					}
				}
				// register the task for the current phase under the target name
				arguments.context.register(eventTask, phase, name);

			}

			tasks = tasks.events;
			// tasks is now a struct where keys are event types
			for (var type in tasks) {

				var eventTask = createTask(arguments.context);
				// loop over the tasks for this event and create subtasks
				for (var task in tasks[type]) {
					eventTask.addSubtask(createTask(arguments.context, task));
				}
				// register the task for the given event
				arguments.context.register(eventTask, "event", name, type);

			}

		}

	}

	private void function readFile(required string path) {

		var content = FileRead(arguments.path);
		var xmlDocument = XmlParse(content, false); //, "cflow.xsd");

		var name = xmlDocument.xmlRoot.xmlAttributes.name;
		// the root element (target) may have an attribute default controller
		if (StructKeyExists(xmlDocument.xmlRoot.xmlAttributes, "defaultcontroller")) {
			variables.defaultControllers[name] = xmlDocument.xmlRoot.xmlAttributes.defaultcontroller;
		}

		var tasks = {};
		var tagNames = ["start", "end", "before", "after"];
		for (var tagName in tagNames) {
			var nodes = XmlSearch(xmlDocument, "/target/#tagName#");
			// we expect at most 1 node of this type
			if (!ArrayIsEmpty(nodes)) {
				tasks[tagName] = getTasksFromChildNodes(nodes[1]);
			}
		}

		tasks["events"] = {};
		var eventNodes = XmlSearch(xmlDocument, "/target/event");
		for (var eventNode in eventNodes) {
			tasks.events[eventNode.xmlAttributes.type] = getTasksFromChildNodes(eventNode);
		}

		var includeNodes = XmlSearch(xmlDocument, "/target/include");
		if (!ArrayIsEmpty(includeNodes)) {
			// create an array that will contain the includes in source order
			tasks["includes"] = [];
			for (var includeNode in includeNodes) {
				ArrayAppend(tasks.includes, includeNode.xmlAttributes);
			}
		}

		variables.tasks[name] = tasks;

	}

	private struct function getTaskFromNode(required xml node) {

		var task = {
			"type" = arguments.node.xmlName
		};
		// we assume the xml is correct, so we can just append the attributes
		StructAppend(task, arguments.node.xmlAttributes);

		// for invoke and dispatch tasks, there can be child tasks that are to be executed if an event is canceled
		if (ArrayContains(["invoke", "dispatch"], task.type)) {
			task["instead"] = getTasksFromChildNodes(arguments.node);
		}

		return task;
	}

	private array function getTasksFromChildNodes(required xml node) {

		var tasks = [];
		var childNodes = arguments.node.xmlChildren;
		var count = ArrayLen(childNodes);
		// it looks like Railo doesn't loop over an xml node list like an array with for .. in
		for (var i = 1; i <= count; i++) {
			ArrayAppend(tasks, getTaskFromNode(childNodes[i]));
		}

		return tasks;
	}

	private void function compileIncludes() {

		var targets = StructFindKey(variables.tasks, "includes", "all");

		// there can be includes that include other includes
		// therefore, we repeat the search for include keys until we find none
		// we know the total number of includes, so if we need to repeat the loop more than that number of times, there is a circular reference
		var count = ArrayLen(targets);
		while (!ArrayIsEmpty(targets)) {
			for (var target in targets) {
				// include.value contains an array of includes
				var includes = Duplicate(target.value); // we make a duplicate, because we are going to remove items from the original array
				for (var include in includes) {
					// get the tasks that belong to this include
					if (!StructKeyExists(variables.tasks, include.target)) {
						throw(type = "cflow", message = "Included target #include.target# does not exist");
					}
					var includeTarget = variables.tasks[include.target];
					// if the target has includes, we have to wait until those are resolved
					// that will happen in a following loop
					if (!StructKeyExists(includeTarget, "includes")) {
						if (StructKeyExists(include, "event")) {
							// an event is specified, only include it if that event is not already defined on the receiving target
							if (!StructKeyExists(target.owner.events, include.event)) {
								if (StructKeyExists(includeTarget.events, include.event)) {
									// the owner key contains a reference to the original tasks struct, so we can modify it
									target.owner.events[include.event] = Duplicate(includeTarget.events[include.event]);
								} else {
									throw(type = "cflow", message = "Event #include.event# not found in included target #include.target#");
								}
							}
						} else {
							// the whole task list of the given target must be included
							// if there are start or before tasks, they have to be prepended to the existing start and before tasks, respectively
							for (var type in ["start", "before"]) {
								if (StructKeyExists(includeTarget, type)) {
									// duplicate the task array, since it may be modified later when setting the default controller
									var typeTasks = Duplicate(includeTarget[type]);
									if (StructKeyExists(target.owner, type)) {
										// append the existing tasks
										for (task in target.owner[type]) {
											ArrayAppend(typeTasks, task);
										}
									}
									target.owner[type] =  typeTasks;
								}
							}
							// for end or after tasks, it's the other way around: we append those tasks to the array of existing tasks
							for (var type in ["after", "end"]) {
								if (StructKeyExists(includeTarget, type)) {
									var typeTasks = Duplicate(includeTarget[type]);
									if (!StructKeyExists(target.owner, type)) {
										target.owner[type] = [];
									}
									for (task in typeTasks) {
										ArrayAppend(target.owner[type], task);
									}
								}
							}

							// now include all events that are not yet defined on this target
							StructAppend(target.owner.events, Duplicate(includeTarget.events), false);

						}
						// this include is now completely processed, remove it from the original array
						ArrayDeleteAt(target.value, 1); // it is always the first item in the array
					} else {
						// this include could not be processed because it has includes itself
						// we cannot process further includes, the order is important
						break;
					}
				}

				// if all includes were processed, there are no items left in the includes array
				if (ArrayIsEmpty(target.value)) {
					StructDelete(target.owner, "includes");
				}
			}

			count--;
			if (count < 0) {
				throw(type = "cflow", message = "Circular reference detected in includes");
			}

			targets = StructFindKey(variables.tasks, "includes", "all");
		}

	}

	/**
	 * Sets default controllers and targets for tasks that have not specified them.
	 **/
	private void function setTaskDefaults() {

		var tasks = JavaCast("null", 0);
		var task = JavaCast("null", 0);
		for (var name in variables.tasks) {
			// if a default controller was specified, set it on all invoke tasks that have no controller
			var target = variables.tasks[name];
			if (StructKeyExists(variables.defaultControllers, name)) {
				// find all tasks that have no controller specified
				tasks = StructFindValue(target, "invoke", "all");
				for (task in tasks) {
					if (!StructKeyExists(task.owner, "controller")) {
						// explicitly set the controller
						task.owner["controller"] = variables.defaultControllers[name];
					}
				}
			}

			// the same thing for dispatch tasks: if no target is specified use the current target
			tasks = StructFindValue(target, "dispatch", "all");
			for (task in tasks) {
				if (!StructKeyExists(task.owner, "target")) {
					task.owner["target"] = name;
				}
			}

			tasks = StructFindValue(target, "render", "all");
			for (task in tasks) {
				// look for templates in a directory with the target name
				task.owner.template = name & "/" & task.owner.template;
			}
		}

	}

	private Task function createTask(required Context context, struct task) {

		var instance = JavaCast("null", 0);
		if (!StructKeyExists(arguments, "task")) {
			instance = new EventTask();
		} else {
			switch (arguments.task.type) {
				case "invoke":
					instance = arguments.context.createInvokeTask(arguments.task.controller, arguments.task.method);
					break;
				case "dispatch":
					instance = arguments.context.createDispatchTask(arguments.task.target, arguments.task.event);
					break;
				case "render":
					instance = arguments.context.createRenderTask(arguments.task.template);
					break;
			}

			// if there are instead tasks, they will become subtasks of the current task
			if (StructKeyExists(arguments.task, "instead")) {
				for (var insteadTask in arguments.task.instead) {
					instance.addSubtask(createTask(arguments.context, insteadTask));
				}
			}
		}

		return instance;
	}

}