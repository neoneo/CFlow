component extends="TaskNode" accessors="true" {

	property String action default="run";
	property String name;
	property String priority default="normal";
	property Numeric timeout default="0";
	property Numeric duration default="0";

}