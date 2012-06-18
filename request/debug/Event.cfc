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

component Event extends="cflow.request.Event" {

	public void function init(required string target, required string type, struct properties = {}) {

		super.init(argumentCollection = arguments);
		// create an array for recording debugging messages
		variables.messages = [];
		variables.children = [variables.messages]; // an array of arrays that contain messages; the last one is the one that is written to
		variables.tickCount = GetTickCount();
		variables.startTime = variables.tickCount;

		// some messages imply the abort message that will follow them:
		variables.impliedAbortMessages = ["cflow.exception", "cflow.redirect"];

	}

	public void function cancel() {
		record("cflow.eventcanceled");
		super.cancel();
	}

	public void function abort() {
		record("cflow.aborted");
		super.abort();
	}

	/**
	 * Records a debugging message. This message will be displayed in debug output.
	 **/
	public void function record(required any metadata, string message = "") {

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
			ArrayAppend(getChildren(), transport);
		}

	}

	public numeric function getTime() {
		return GetTickCount() - variables.startTime;
	}

	package void function recordStart(required any metadata, string message = "") {

		// record the message first
		record(arguments.metadata, arguments.message);
		// create a child messages array
		var children = [];
		// put it on the last recorded message
		var lastMessage = getLastMessage();
		lastMessage.children = children;
		// keep the tick count for later
		lastMessage.tickCount = GetTickCount();
		// push it on the array of children arrays
		ArrayAppend(variables.children, children);

	}

	package void function recordEnd() {

		// remove the last children array
		ArrayDeleteAt(variables.children, ArrayLen(variables.children));
		// the last message is now the message that is ended here
		var lastMessage = getLastMessage();

		var tickCount = GetTickCount();
		lastMessage.duration = tickCount - lastMessage.tickCount; // time between start and end calls
		lastMessage.time = tickCount - variables.startTime // total time elapsed since object instantiation
		StructDelete(lastMessage, "tickCount");

	}

	/**
	 * Calls recordEnd() for all open recordStart() calls. This method is used as a shortcut when an exception needs to be handled.
	 **/
	package void function recordEndAll() {

		// call recordEnd() n - 1 times (note the strictly smaller comparison operator)
		var count = ArrayLen(variables.children);
		for (var i = 1; i < count; i++) {
			recordEnd();
		}

	}

	package array function getMessages() {
		return variables.messages;
	}

	/**
	 * Returns the array in which to record messages.
	 **/
	private array function getChildren() {
		return variables.children[ArrayLen(variables.children)];
	}

	/**
	 * Returns the last message of the children array.
	 **/
	private struct function getLastMessage() {

		var children = getChildren();

		return !ArrayIsEmpty(children) ? children[ArrayLen(children)] : {message = ""};
	}

}