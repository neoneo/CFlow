<!---
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
--->

<style type="text/css">
	#cflow {
		font-family: Verdana, sans-serif;
		font-size: 9pt;
		color: #000;
	}

	#cflow > h1 {
		font-weight: bold;
		font-size: 12pt;
		padding: 2px 16px;
	}

	#cflow ul {
		list-style-type: none;
		margin: 0;
		padding: 0 12px;
	}

	#cflow li {
		padding: 0px;
		border: 2px dashed transparent;
	}

	#cflow .duration {
		font-weight: bold;
		float: right;
	}

	#cflow .total {
		padding: 0 16px;
	}

	#cflow .message, #cflow .data {
		border: 1px solid #000;
		padding: 2px;
	}

	#cflow .message {
		overflow: hidden;
		background-color: #ffb200;
	}

	#cflow .data {
		margin-top: 1px;
	}

	#cflow .phase > .message {
		background-color: #9c3;
		font-weight: bold;
	}

	#cflow .phase > .data {
		background-color: #cf3;
	}

	#cflow .task > .message {
		background-color: #99f;
	}

	#cflow .redirect a {
		text-decoration: underline;
		color: #fff;
	}

	#cflow .redirect > .message {
		background-color: #666;
		color: #fff;
	}

	#cflow .task > .data {
		background-color: #ccf;
	}

	#cflow .eventcanceled > .message,
	#cflow .eventwithouttasks > .message,
	#cflow .aborted > .message {
		background-color: #f60;
	}

	#cflow .exception > .message {
		background-color: #dc322f;
		font-weight: bold;
		color: #fff;
	}

	#cflow .exception > .data {
		background-color: #fc0;
	}

	#cflow .exception h2 {
		font-size: 11pt;
	}
</style>

<cfoutput>
<div id="cflow">
	#data._debugoutput#
</div>
</cfoutput>

<script>
	var cflow = {

		node: document.getElementById("cflow"),

		getActiveListItem: function (node) {
			var listItem = node;

			while (listItem.tagName.toLowerCase() !== "li" && listItem !== this.node) {
				listItem = listItem.parentNode;
			}

			if (listItem === this.node) {
				listItem = null;
			}

			return listItem;
		}

	};

	cflow.node.addEventListener("mouseover", function (e) {
		var listItem = cflow.getActiveListItem(e.target);
		if (listItem) {
			listItem.style.borderColor = "#f00";
		}
	}, false);

	cflow.node.addEventListener("mouseout", function (e) {
		var listItem = cflow.getActiveListItem(e.target);
		if (listItem) {
			listItem.style.borderColor = "";
		}
	}, false);

	cflow.node.addEventListener("click", function (e) {
		var listItem = cflow.getActiveListItem(e.target);
		if (listItem) {
			var dataDiv = listItem.children[1];
			if (dataDiv) {
				dataDiv.style.display = dataDiv.style.display === "none" ? "" : "none";
			}
		}
	}, false);

</script>
