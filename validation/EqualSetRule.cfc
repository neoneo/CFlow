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

component EqualSetRule extends="SetRule" {

	public boolean function test(required struct data) {

		var result = false;

		var set = toArray(getValue(arguments.data));
		var compareSet = getParameterValue(arguments.data);

		// we only reckon with sets that have unique values, so the number of elements of both sets is the same
		if (ArrayLen(set) == ArrayLen(compareSet)) {
			result = isSubset(set, compareSet);
		}

		return result;
	}

}