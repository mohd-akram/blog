---
title: Parsing JSON in Forty Lines of Awk
description: A single-function JSON parser for the POSIX shell.
---

JSON is not a friendly format to the Unix shell --- it's hierarchical, and
cannot be reasonably split on any character (other than the newline, which is
not very useful) as that character might be included in a string. There are
well-known tools such as [jq](https://jqlang.org) that let you correctly parse
JSON documents in the shell, but all require an additional dependency. Another
option is to use Python, which is ubiquitous enough that it can be expected to
be installed on virtually every machine, and for new projects would be the
recommended option.

However, I already had a working POSIX shell script that now had a requirement
to read and parse JSON. It had previously extracted values from HTML which,
while also being hierarchical, can be reliably split on certain characters (the
angle brackets) for basic extraction of values. awk is the closest thing to a
real programming language that's available in the POSIX shell, so I thought I'd
try to write a basic JSON parser in it. I had already written a full-blown
[one](https://github.com/mohd-akram/jawk) before, so I knew it was doable, but
I needed something more concise.

First, there are some caveats. JSON is [notoriously
tricky](https://seriot.ch/projects/parsing_json.html) to get completely right,
despite its simple grammar. The following code assumes that it will be fed
valid JSON. It has some basic validation as a function of the parsing and will
most likely throw an error if it encounters something strange, but there are no
guarantees beyond that. In my case, I'm reading JSON from a single, trusted
source, so this is an acceptable constraint.

The interface is simple, a single function that accepts a JSON document and a
dotted path to a key or array index, and returns the corresponding value. It
can be used like so:

```awk
items = get_json_value(json, "payload.items")
while ((item = get_json_value(items, i++))) {
	type = decode_json_string(get_json_value(item, "type"))
	name = decode_json_string(get_json_value(item, "name"))
}
```

To keep things simple, the same function handles both arrays and objects. In
JavaScript, arrays are roughly equivalent to objects with integer keys, and we
use the same approach here. This is the
[implementation](https://gist.github.com/mohd-akram/1c0d4cb337b62e3cce0ab7e02e6281fd),
expanded and annotated:

```awk
# The function takes two parameters, the JSON object/array and the desired key
# The rest are local variables (awk only allows local variables in the form
# of function parameters)
function get_json_value( \
	s, key,
	type, all, rest, isval, i, c, j, k \
) {
	# Get the type of object by its first character
	type = substr(s, 1, 1)

	# If it's neither an object, nor an array, throw an error
	if (type != "{" && type != "[") error("invalid json array/object " s)

	# This variable is needed for when we recursively call the function
	# It will be true if the key argument is omitted, since undefined
	# variables in awk can behave as either a string or a number
	all = key == "" && key == 0

	# Get the first part of the key (which we will be looking for)
	# if the path is dotted and save the rest for now
	if (!all && (j = index(key, "."))) {
		rest = substr(key, j+1)
		key = substr(key, 1, j-1)
	}

	# k is the current key
	# If this is an array, it is the index, which starts at 0
	if (type == "[") k = 0

	# isval keeps track of whether we are looking at a JSON key or value
	# In an array, all items are values
	isval = type == "["

	# Loop over the characters in the provided JSON
	# Skip the opening brace or bracket (to avoid infinite recursion) and
	# increment the index by the length of the token
	for (i = 2; i < length(s); i += length(c)) {
		# Temporarily assign the first character to our token variable
		# until we figure out its type
		c = substr(s, i, 1)

		# If it's a double quote, then we expect a string
		if (c == "\"") {
			# Get its length
			if (!match(substr(s, i), /^"(\\.|[^\\"])*"/))
				error("invalid json string " substr(s, i))
			# And extract the string
			c = substr(s, i, RLENGTH)
			# If we're not expecting a value, then it's a key, so
			# trim the quotes and save it
			if (!isval) k = substr(c, 2, length(c)-2)
		}

		# If it's an opening brace or bracket, then we expect an object
		# or array
		else if (c == "{" || c == "[") {
			# If this is the object we're looking for and we need
			# a nested value, pass the rest of the dotted key
			# Otherwise, get the whole object
			c = (!all && k == key && !(rest == "" && rest == 0)) ? \
				get_json_value(substr(s, i), rest) : \
				get_json_value(substr(s, i))
		}

		# If it's a closing brace or bracket, we've reached the end of
		# the object or array, so exit the loop
		else if (c == "}" || c == "]") break

		# If we find a comma in an object, the next item will be a key,
		# so reset isval
		else if (c == ",") isval = type == "["

		# For the colon, isval needs to be set to true, but that is done
		# later (see why below)
		else if (c == ":") ;

		# Ignore whitespace
		else if (c ~ /[[:space:]]/) continue

		# Match anything else
		else {
			# This will match numbers, booleans and null
			# Find the next closing bracket, brace, comma or
			# whitespace, as those terminate values
			if (!match(substr(s, i), /[]},[:space:]]/))
				error("invalid json value " substr(s, i))
			# Extract the value
			c = substr(s, i, RSTART-1)
		}

		# If this is a value, and the key matches, we've found our
		# desired object, so return it
		if (!all && isval && k == key) return c

		# If we see a colon in an object, the next token is a value
		# This needs to be after the previous statement to not capture
		# the colon itself
		if (type == "{" && c == ":") isval = 1

		# If this is an array and we see a comma, increment the index
		if (type == "[" && c == ",") ++k
	}

	# If we're here, it means we didn't find the value we're looking for
	# so only return something if the whole array or object was requested
	if (all) return substr(s, 1, i)
}
```

To make the parser more useful, you'll also need a function to do some decoding
of JSON strings. This is a simple one, which handles everything except Unicode
escape sequences, but throws an error if it encounters one:

```awk
function decode_json_string(s, out, esc) {
	if (substr(s, 1, 1) != "\"" || substr(s, length(s), 1) != "\"")
		error("invalid json string " s)

	s = substr(s, 2, length(s)-2)

	esc["b"] = "\b"; esc["f"] = "\f"; esc["n"] = "\n"; esc["\""] = "\""
	esc["r"] = "\r"; esc["t"] = "\t"; esc["/"] = "/" ; esc["\\"] = "\\"

	while (match(s, /\\/)) {
		if (!(substr(s, RSTART+1, 1) in esc))
			error("unknown json escape " substr(s, RSTART, 2))
		out = out substr(s, 1, RSTART-1) esc[substr(s, RSTART+1, 1)]
		s = substr(s, RSTART+2)
	}

	return out s
}
```

And finally, since there is no built-in error function in awk, you can use
something like this:

```awk
function error(msg) {
	printf "%s: %s\n", ARGV[0], msg > "/dev/stderr"
	exit 1
}
```
