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
# Get one value
name = decode_json_string(get_json_value(json, "author.name"))

# Loop over an object
get_json_value(json, "dependencies", deps)
for (name in deps)
	version = decode_json_string(deps[name])

# Loop over an array
get_json_value(json, "payload.items", items)
for (i = 0; items[i]; i++) {
	get_json_value(items[i], null, item)
	type = decode_json_string(item["type"])
	name = decode_json_string(item["name"])
}
```

To keep things simple, the same function handles both arrays and objects. In
JavaScript, arrays are roughly equivalent to objects with integer keys, and we
use the same approach here. This is the
[implementation](https://gist.github.com/mohd-akram/1c0d4cb337b62e3cce0ab7e02e6281fd),
expanded and annotated:

```awk
# The function takes three parameters: the JSON object/array, the desired key,
# and an optional array to be filled if the key points to an object or array.
# The rest are local variables (awk only allows local variables in the form
# of function parameters)
function get_json_value( \
	s, key, a,
	skip, type, all, rest, isval, i, c, k, null \
) {
	# Trim leading whitespace, if any
	if (match(s, /^[[:space:]]+/)) s = substr(s, RLENGTH+1)

	# Get the type of value by its first character
	type = substr(s, 1, 1)

	# This variable is needed for when we recursively call the function
	# It will be true if the key argument is undefined, since such
	# variables can behave as either a string or a number in awk
	all = key == "" && key == 0

	# If this is a primitive
	if (type != "{" && type != "[") {
		# Ensure a key is not passed
		if (!all) error("invalid json array/object " s)

		# Parse the value
		if (!match(s, /^(null|true|false|"(\\.|[^\\"])*"|[.0-9Ee+-]+)/))
			error("invalid json value " s)

		# And return it
		return substr(s, 1, RLENGTH)
	}

	# Get the first part of the key (which we will be looking for)
	# if the path is dotted and save the rest for now
	if (!all && (i = index(key, "."))) {
		rest = substr(key, i+1)
		key = substr(key, 1, i-1)
	}

	# isval keeps track of whether we are looking at a JSON key or value
	# In an array, all items are values
	# k is the current key
	# If this is an array, it is the index, which starts at 0
	if ((isval = type == "[")) k = 0

	# Loop over the characters in the provided JSON
	# Skip the opening brace or bracket (to avoid infinite recursion) and
	# increment the index by the length of the token
	for (i = 2; i <= length(s); i += length(c)) {
		# Skip over whitespace
		if (match(substr(s, i), /^[[:space:]]+/)) {
			c = substr(s, i, RLENGTH)
			continue
		}

		# Temporarily assign the first character to our token variable
		c = substr(s, i, 1)

		# If it's a closing brace or bracket, we've reached the end of
		# the object or array, so exit the loop
		if (c == "}" || c == "]") break

		# If we find a comma in an object, the next item will be a key,
		# so reset isval. If it's an array, increment the index
		else if (c == ",") { if ((isval = type == "[")) ++k }

		# If we see a colon, the next token will be a value
		else if (c == ":") isval = 1

		# Otherwise, we expect a JSON value
		else {
			# If the key matches, this is our desired value,
			# so pass the rest of the key and return the result
			if (!all && k == key && isval)
				return get_json_value(substr(s, i), rest, a)

			# Otherwise, get the full value
			c = get_json_value(substr(s, i), null, null, 1)

			# And add it to the associative array
			if (all && !skip && isval) a[k] = c

			# If this is a string and we're not expecting a value,
			# then it's a key, so trim the quotes and save it
			if (c ~ /^"/ && !isval) k = substr(c, 2, length(c)-2)
		}
	}

	# Do a basic check that the object or array was properly closed
	if ((type == "{" && c != "}") || (type == "[" && c != "]"))
		error("unterminated json array/object " s)

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
	if (s !~ /^"./ || substr(s, length(s), 1) != "\"")
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
