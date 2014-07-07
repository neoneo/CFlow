component extends="TaskNode" accessors="true" {

	property String url;
	property String target;
	property String event;
	property Boolean permanent default="false";
	property Struct parameters;

}