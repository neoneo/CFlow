/*
   Copyright 2012 Neo Neo

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

component XmlReader {

	variables.tasks = {}; // lists of tasks per target
	variables.abstractTargetNames = []; // list of targets that are abstract
	variables.defaultControllers = {}; // default controllers per target

	variables.complexTaskTypes = ["invoke", "dispatch", "if", "else", "thread"]; // complex tasks are tasks that can contain other tasks

	public void function init(required Context context) {
		variables.context = arguments.context;
	}

	public struct function read(required string path) {

		var absolutePath = ExpandPath(arguments.path);
		var list = DirectoryList(absolutePath, true, "name", "*.xml");

		for (var name in list) {
			readFile(absolutePath & "/" & name);
		}

		return variables.tasks;
	}

	public void function register() {

		construct();

		var phases = ["start", "end", "before", "after"];
		// variables.tasks is a struct where each key is a target name
		for (var name in variables.tasks) {

			var tasks = variables.tasks[name];
			// tasks contains all the tasks for this target, stored by phase and by event
			// first create tasks for all phases
			for (var phase in phases) {
				// always create the task, even if it remains empty, because otherwise the task is created for each request later
				if (StructKeyExists(tasks, phase)) {
					for (var task in tasks[phase]) {
						// register the task for the current phase under the target name
						variables.context.register(createTask(task), phase, name);
					}
				}
			}

			tasks = tasks.events;
			// tasks is now a struct where keys are event types
			for (var type in tasks) {
				// loop over the tasks for this event and create subtasks
				for (var task in tasks[type]) {
					// register the task for the given event
					variables.context.register(createTask(task), "event", name, type);
				}
			}
		}

		// purge all collected information so that if new reads happen, they are not linked to these tasks
		variables.tasks = {};
		variables.defaultControllers = {};

	}

	public struct function construct() {

		// use the target as the view directory name for start, before, after, and end tasks only (argument false)
		setViewDirectories(false);

		// process all include nodes
		compileIncludes();

		// set all invoke tasks' controllers without a controller to the default controller of the target
		setDefaultControllers();

		// all dispatch and redirect tasks without a target will go to the target that owns the event
		setDefaultDispatchTargets();
		setDefaultRedirectTargets();

		// use the target name as the directory name for event tasks
		// so an included event will look for its views in the receiving target's directory
		setViewDirectories(true);

		// throw away the abstract targets
		// if we don't do this, the framework will try to create objects, which is unnecessary, and might result in exceptions
		removeAbstractTargets();

		return variables.tasks;
	}

	private void function readFile(required string path) {

		var content = FileRead(arguments.path);
		var xmlDocument = XmlParse(content, false);

		// the root element can be targets or target
		switch (xmlDocument.xmlRoot.xmlName) {
			case "targets":
				// get all targets and create task definitions
				var targets = xmlDocument.xmlRoot.xmlChildren;
				for (var target in targets) {
					getTasksFromTargetNode(target);
				}
				break;

			case "target":
				getTasksFromTargetNode(xmlDocument.xmlRoot);
				break;
		}

	}

	private void function getTasksFromTargetNode(required xml node) {

		var name = arguments.node.xmlAttributes.name;

		if (StructKeyExists(arguments.node.xmlAttributes, "abstract") && arguments.node.xmlAttributes.abstract) {
			// abstract target
			ArrayAppend(variables.abstractTargetNames, name);
		}

		// the node may have an attribute default controller
		if (StructKeyExists(arguments.node.xmlAttributes, "defaultcontroller")) {
			variables.defaultControllers[name] = arguments.node.xmlAttributes.defaultcontroller;
		}

		var tasks = {};
		for (var tagName in ["start", "end", "before", "after"]) {
			var nodes = XmlSearch(arguments.node, tagName);
			// we expect at most 1 node of this type
			if (!ArrayIsEmpty(nodes)) {
				tasks[tagName] = getTasksFromChildNodes(nodes[1]);
			}
		}

		tasks.events = {};
		var eventNodes = XmlSearch(arguments.node, "event");
		for (var eventNode in eventNodes) {
			tasks.events[eventNode.xmlAttributes.type] = getTasksFromChildNodes(eventNode);
		}

		var includeNodes = XmlSearch(arguments.node, "include");
		if (!ArrayIsEmpty(includeNodes)) {
			// create an array that will contain the includes in reverse source order
			// the first include's tasks must be executed first, so they must be created last (see compileIncludes)
			tasks.includes = [];
			for (var includeNode in includeNodes) {
				ArrayPrepend(tasks.includes, includeNode.xmlAttributes);
			}
		}

		variables.tasks[name] = tasks;

	}

	private struct function getTaskFromNode(required xml node) {

		var task = {
			$type = arguments.node.xmlName
		};
		// we assume the xml is correct, so we can just append the attributes
		StructAppend(task, arguments.node.xmlAttributes);

		// for complex tasks, there can be child tasks that are to be executed if an event is canceled
		if (ArrayFind(variables.complexTaskTypes, task.$type) > 0) {
			task.sub = getTasksFromChildNodes(arguments.node);
		}

		return task;
	}

	private array function getTasksFromChildNodes(required xml node) {

		var tasks = [];
		var childNodes = arguments.node.xmlChildren;

		for (var childNode in childNodes) {
			ArrayAppend(tasks, getTaskFromNode(childNode));
		}

		return tasks;
	}

	private void function compileIncludes() {

		// first get all the top level includes and process them
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
						Throw(type = "cflow.request", message = "Included target '#include.target#' not found");
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
									Throw(type = "cflow.request", message = "Event '#include.event#' not found in included target '#include.target#'");
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
				Throw(type = "cflow.request", message = "Circular reference detected in includes");
			}

			targets = StructFindKey(variables.tasks, "includes", "all");
		}

		// now process any includes that are defined in an event
		// those includes must specify an event
		// it is still true that there can be recursion
		var includes = StructFindValue(variables.tasks, "include", "all");
		// remove items that use the value 'include' but are not includes
		for (var i = ArrayLen(includes); i >= 1; i--) {
			if (includes[i].key != "$type") {
				ArrayDeleteAt(includes, i);
			}
		}

		var count = ArrayLen(includes);
		while (!ArrayIsEmpty(includes)) {
			// loop backwards over the includes, because one include is generally going to be replaced by more than one task
			// in the case of multiple includes in one event, looping forward would invalidate the path to the include entry
			for (var i = ArrayLen(includes); i >= 1; i--) {
				var include = includes[i];
				// target and event are mandatory attributes
				if (!StructKeyExists(variables.tasks, include.owner.target)) {
					Throw(type = "cflow.request", message = "Included target '#include.owner.target#' not found");
				}
				var target = variables.tasks[include.owner.target];

				// the event must be defined in this target
				if (!StructKeyExists(target.events, include.owner.event)) {
					Throw(type = "cflow.request", message = "Included target '#include.owner.target#' does not define event '#include.owner.event#'");
				}
				// get the tasks that have to be inserted instead of the include
				var eventTasks = target.events[include.owner.event];
				// if these tasks contain an include, do not proceed
				var eventIncludes = StructFindValue({t = eventTasks}, "include", "all"); // put the event tasks in a struct to be able to call StructFindValue()
				var proceed = true;
				for (var eventInclude in eventIncludes) {
					if (eventInclude.key == "$type") {
						proceed = false;
						break;
					}
				}

				if (proceed) {
					// get a reference to the parent array of the include from the path
					// the path is of the form ".target.events.eventType[taskIndex].$type", but there can be deeper nesting
					// first pick up the array index
					var indices = REMatch("[0-9]+(?=])", include.path); // there can be more than one, but we want only the last one
					var index = Val(indices[ArrayLen(indices)]);
					// cut off the index and .$type from the path
					var path = Left(include.path, Len(include.path) - Len("[#index#].$type"));
					// get the reference
					var parent = Evaluate("variables.tasks#path#");
					// remove the include entry
					ArrayDeleteAt(parent, index);
					// insert the include's tasks at that position
					for (var j = ArrayLen(eventTasks); j >= 1; j--) {
						ArrayInsertAt(parent, index, eventTasks[j]);
					}
					// remove the include struct
					ArrayDeleteAt(includes, i);
				}
			}

			count--;
			if (count < 0) {
				Throw(type = "cflow.request", message = "Circular reference detected in includes");
			}
		}

	}

	/**
	 * Sets the controllers explicitly to each invoke task, if possible.
	 **/
	private void function setDefaultControllers() {

		for (var name in variables.tasks) {
			var target = variables.tasks[name];

			// if a default controller was specified, set it on all invoke tasks that have no controller
			if (StructKeyExists(variables.defaultControllers, name)) {
				// find all tasks that have no controller specified
				var tasks = StructFindValue(target, "invoke", "all");
				for (var task in tasks) {
					if (task.key == "$type") {
						if (!StructKeyExists(task.owner, "controller")) {
							// explicitly set the controller
							task.owner.controller = variables.defaultControllers[name];
						}
					}
				}
			}
		}

	}

	/**
	 * Sets default targets for dispatch tasks that have not specified it.
	 **/
	private void function setDefaultDispatchTargets() {

		for (var name in variables.tasks) {
			var target = variables.tasks[name];

			// for dispatch task with no target use the current target
			var tasks = StructFindValue(target, "dispatch", "all");
			for (var task in tasks) {
				if (task.key == "$type") {
					if (!StructKeyExists(task.owner, "target")) {
						task.owner["target"] = name;
					}
					// if the event goes to the same target, and is defined immediately in the before or after phase, this would cause an infinite loop
					if (task.owner.target == name && (task.path contains ".before[" or task.path contains ".after[") && task.path does not contain ".sub[") {
						Throw(
							type = "cflow.request",
							message = "Dispatching event '#task.owner.event#' to the current target '#name#' will cause an infinite loop",
							detail = "Do not define dispatch tasks without a target in the before or after phases, unless the task is run conditionally"
						);
					}
				}

			}

		}

	}

	/**
	 * Modifies the view name so it uses the target name as the directory (within the view mapping).
	 * The boolean argument specifies if the change is applied to render tasks in event phases (true) or in the other phases (false).
	 * This is important when targets with render tasks are included.
	 * If the render task is defined in an event, the receiving target has to implement that view.
	 * If the render task is defined elsewhere, the originating target has to implement it.
	 **/
	private void function setViewDirectories(required boolean eventPhase) {

		for (var name in variables.tasks) {
			var target = variables.tasks[name];

			var tasks = StructFindValue(target, "render", "all");
			for (task in tasks) {
				if (task.key == "$type") {
					if (arguments.eventPhase && task.path contains ".events." || !arguments.eventPhase && task.path does not contain ".events.") {
						// check for the existence of a view attribute, as some other task could have an attribute with the value 'render'
						// prepend the target name as the directory name
						task.owner.view = name & "/" & task.owner.view;
					}
				}
			}
		}

	}

	/**
	 * Sets default targets for redirect tasks that have not specified it.
	 **/
	private void function setDefaultRedirectTargets() {

		for (var name in variables.tasks) {
			var target = variables.tasks[name];

			// for dispatch task with no target use the current target
			var tasks = StructFindValue(target, "redirect", "all");
			for (var task in tasks) {
				if (task.key == "$type") {
					// do nothing if the redirect is to a fixed url, or if it has a target already
					if (!StructKeyExists(task.owner, "url")) {
						if (!StructKeyExists(task.owner, "target")) {
							task.owner["target"] = name;
						}

						// if the redirect goes to the same target and is defined outside the event phase, this would cause an infinite loop
						if (task.owner.target == name && task.path does not contain ".events." && task.path does not contain ".sub[") {
							Throw(
								type = "cflow.request",
								message = "Redirecting to event '#task.owner.event#' on the current target '#name#' will cause an infinite loop",
								detail = "Do not define redirect tasks without a target outside the event phase, unless the task is run conditionally"
							);
						}
					}
				}
			}

		}

	}

	private void function removeAbstractTargets() {

		for (var name in variables.abstractTargetNames) {
			StructDelete(variables.tasks, name);
		}

	}

	private Task function createTask(struct task) {

		var instance = JavaCast("null", 0);

		if (!StructKeyExists(arguments, "task")) {
			instance = arguments.context.createPhaseTask();
		} else {
			switch (arguments.task.$type) {
				case "invoke":
					if (!StructKeyExists(arguments.task, "controller")) {
						Throw(type = "cflow.request", message = "No controller associated with invoke task for handler '#arguments.task.handler#'");
					}
					instance = variables.context.createInvokeTask(arguments.task.controller, arguments.task.handler);
					break;

				case "dispatch":
					instance = variables.context.createDispatchTask(arguments.task.target, arguments.task.event);
					break;

				case "render":
					instance = variables.context.createRenderTask(arguments.task.view);
					break;

				case "redirect":
					local.url = StructKeyExists(arguments.task, "url") ? arguments.task.url : "";
					var target = StructKeyExists(arguments.task, "target") ? arguments.task.target : ""
					var event = StructKeyExists(arguments.task, "event") ? arguments.task.event : ""
					var parameters = StructCopy(arguments.task);
					var permanent = StructKeyExists(arguments.task, "permanent") && arguments.task.permanent;
					// delete the formal attributes so the additional attributes are left
					StructDelete(parameters, "$type");
					StructDelete(parameters, "permanent");
					StructDelete(parameters, "url");
					StructDelete(parameters, "target");
					StructDelete(parameters, "event");
					StructDelete(parameters, "advice");

					instance = variables.context.createRedirectTask(local.url, target, event, parameters, permanent);
					break;

				case "if":
					instance = variables.context.createIfTask(arguments.task.condition);
					break;

				case "else":
					var condition = StructKeyExists(arguments.task, "condition") ? arguments.task.condition : "";
					instance = variables.context.createElseTask(condition);
					break;

				case "set":
					// the variable name is the first (and only) attribute
					var attributes = StructCopy(arguments.task);
					var overwrite = !StructKeyExists(arguments.task, "overwrite") || arguments.task.overwrite;
					StructDelete(attributes, "$type");
					StructDelete(attributes, "overwrite");
					StructDelete(attributes, "advice");

					var name = ListFirst(StructKeyList(attributes)); // pick up the attribute (=variable) name
					var expression = arguments.task[name]; // pick up the attribute value (the expression)
					instance = variables.context.createSetTask(name, expression, overwrite);
					break;

				case "thread":
					// all attributes are optional
					var action = StructKeyExists(arguments.task, "action") ? arguments.task.action : "run";
					var name = StructKeyExists(arguments.task, "name") ? arguments.task.name : "";
					var priority = StructKeyExists(arguments.task, "priority") ? arguments.task.priority : "normal";
					var timeout = StructKeyExists(arguments.task, "timeout") ? arguments.task.timeout : 0;
					var duration = StructKeyExists(arguments.task, "duration") ? arguments.task.duration : 0;

					instance = variables.context.createThreadTask(action, name, priority, timeout, duration);
					break;

				case "task":
					// create an instance of the component, and pass all attributes as arguments except the default attributes
					var argumentCollection = {};
					// workaround for Railo bug 1798, can't use StructCopy to copy xml structs
					var fixedAttributes = ["component", "advice"];
					for (var attribute in xmlAttributes) {
						if (ArrayFind(fixedAttributes, attribute) == 0) {
							argumentCollection[attribute] = xmlAttributes[attribute];
						}
					}
					instance = new "#xmlAttributes.component#"(argumentCollection = argumentCollection);
					break;

			}

			// check for subtasks
			if (StructKeyExists(arguments.task, "sub")) {
				for (var subtask in arguments.task.sub) {
					instance.addSubtask(createTask(subtask));
				}
			}

			// check if the task should be decorated by an advice
			if (StructKeyExists(arguments.task, "advice")) {
				var advices = ListToArray(arguments.task.advice);
				// the first advice should be invoked first, so it is the last one to decorate the task
				for (var i = ArrayLen(advices); i >= 1; i--) {
					instance = new "#advices[i]#"(instance);
				}
			}
		}

		return instance;
	}

}