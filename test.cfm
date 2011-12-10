<cfscript>
	a = true;
	b = false;
	//writeoutput(a && !b);

	c = new Handler("Jeroen");
	writeoutput(c["getName"]());
</cfscript>