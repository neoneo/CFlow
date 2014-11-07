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

component DebugEvent extends="cflow.Event" {

	// create an array for recording debugging messages
	variables.messages = CreateObject("java", "java.util.ArrayList").init();
	// the fact that events can dispatch events, and tasks can contain tasks, means that this is a recursive thing
	// we need to know when a branch in the tree ends
	// therefore, for every branch in the tree we need a messages array
	// so create an array that will contain the message arrays of the currently active branches
	// the last item (an array) in that array will be the currently running branch, so we write messages to that array
	variables.branches = CreateObject("java", "java.util.ArrayList").init();
	// start writing to the messages array
	ArrayAppend(variables.branches, variables.messages);
	variables.tickCount = GetTickCount();
	variables.startTime = variables.tickCount;

	// some messages imply the abort message that will follow:
	variables.impliedAbortMessages = ["cflow.exception", "cflow.redirect"];

	public void function cancel() {
		debug("cflow.eventcanceled");
		super.cancel();
	}

	public void function abort() {
		debug("cflow.aborted");
		super.abort();
	}

	public boolean function dispatch(required string eventType) {

		debugStart({targetName = getTarget(), eventType = arguments.eventType}, "cflow.dispatch");
		var result = super.dispatch(arguments.eventType);
		debugEnd();

		return result;
	}

	/**
	 * Records a debugging message. This message will be displayed in debug output.
	 **/
	public void function debug(required any metadata, string message = "") {

		// if metadata is a simple value and message is not defined, we interpret metadata as the message
		local.message = arguments.message;
		if (IsSimpleValue(arguments.metadata) && Len(arguments.message) == 0) {
			local.message = arguments.metadata;
		} else {
			local.metadata = arguments.metadata;
			if (Len(arguments.message) == 0) {
				local.message = "Dump";
			}
		}

		// record the message
		// only record the abort message if it is not implied by the previous message
		if (local.message != "cflow.aborted" || ArrayFind(variables.impliedAbortMessages, getLastMessage().message) == 0) {
			var tickCount = GetTickCount();
			var transport = {
				message = local.message,
				target = getTarget(),
				event = getType(),
				elapsed = tickCount - variables.tickCount // time elapsed since previous message
			};
			variables.tickCount = tickCount;
			if (StructKeyExists(local, "metadata")) {
				transport.metadata = local.metadata;
			}
			ArrayAppend(getBranch(), transport);
		}

	}

	public numeric function getTime() {
		return GetTickCount() - variables.startTime;
	}

	package void function debugStart(required any metadata, string message = "") {

		// a new branch starts
		// record the message first
		debug(arguments.metadata, arguments.message);
		// create a messages array
		var messages = CreateObject("java", "java.util.ArrayList").init();
		// put it on the last recorded message
		// this is the message that spawns the new branch
		var lastMessage = getLastMessage();
		lastMessage.children = messages;
		// keep the tick count for later
		lastMessage.tickCount = GetTickCount();
		// push it on the branches array
		// this makes this branch the active one
		ArrayAppend(variables.branches, messages);

	}

	package void function debugEnd() {

		// remove the last messages array
		ArrayDeleteAt(variables.branches, ArrayLen(variables.branches));

		// the last message is now the branch that has ended here
		var lastMessage = getLastMessage();
		// update it with some statistics
		var tickCount = GetTickCount();
		lastMessage.duration = tickCount - lastMessage.tickCount; // time between start and end calls
		lastMessage.time = tickCount - variables.startTime; // total time elapsed since object instantiation
		StructDelete(lastMessage, "tickCount");

	}

	/**
	 * Calls debugEnd() for all open debugStart() calls. This method is used as a shortcut when an exception needs to be handled.
	 **/
	package void function debugEndAll() {

		// call debugEnd() n - 1 times (note the strictly smaller comparison operator)
		var count = ArrayLen(variables.branches);
		for (var i = 1; i < count; i++) {
			debugEnd();
		}

	}

	package array function getMessages() {
		return variables.messages;
	}

	/**
	 * Returns the array in which to record messages.
	 **/
	public array function getBranch() {
		return variables.branches[ArrayLen(variables.branches)];
	}

	/**
	 * Returns the last message of the branches array.
	 **/
	private struct function getLastMessage() {

		var branches = getBranch();

		return !ArrayIsEmpty(branches) ? branches[ArrayLen(branches)] : {message = ""};
	}

	// PACKAGE OVERRIDES

	public void function setRejoin(required boolean value) {
		// this method is defined with package access in the superclass
		super.setRejoin(arguments.value);
	}

	public cflow.Response function getResponse() {
		return super.getResponse();
	}

	public void function merge(required Event event) {
		super.merge(arguments.event);
	}

}