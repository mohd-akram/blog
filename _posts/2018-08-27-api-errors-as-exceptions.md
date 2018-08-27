---
title: API Errors As Exceptions
---

Here's a very simple and familiar way to implement errors in your JSON API
without wracking your brain too hard, in two steps:

1. Return a `4xx` HTTP status code.
2. Return a JSON object with a `name` and a `message` property.

No top-level `{ "error": {} }` or `{ "errors": [] }` necessary.

Example response:

    HTTP/1.1 400 Bad Request
    Content-Type: application/json

    { "name": "Error", "message": "Invalid request" }

The `name` property is the name of your error and looks like a class name, eg.
`Error`, `RangeError` or `TypeError` and `message` is a human-readable string
describing the error. This convention matches what [JavaScript
uses](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error)
which makes sense for a JSON API as well. Given this, we can turn an error
response into a proper JavaScript `Error` like so:

```javascript
// api.js

// Our error class with a default name
export class APIError extends Error {}
APIError.prototype.name = 'APIError';

function getError(url, params, res) {
  const { name, message, ...info } = res;
  const error = new APIError(message);
  // Set the error's name from the response
  error.name = name;
  // Copy any additional properties
  Object.assign(error, info);
  // Add properties for convenience
  error.params = params;
  error.url = url;
  return error;
}

// Our API request wrapper
export async function post(url, params) {
  const response = await fetch(url, {
    method: 'POST',
    body: JSON.stringify(params)
  });
  const res = await response.json();
  if (response.ok)
    return res;
  throw getError(url, params, res);
}
```

And this is how to check for errors:

```javascript
import * as api from './api';

async function main() {
  try {
    await api.post('/things', { name: 'My thing' });
  } catch (e) {
    // Rethrow non-API errors
    if (!(e instanceof api.APIError))
      throw e;
    // Handle API errors
    console.error(`${e.name} at ${e.url}`);
    if (e.name == 'FatalError')
      console.error('This is fine.')
  }
}

main();
```

You now have nicer error handling with descriptive names and stack traces.

Error Classes
-------------

This can be taken one step further by using separate classes for each error
type, which can be less error-prone than checking `name`:

```javascript
// api.js
const errors = {};

function addErrorClass(name, base = Error) {
  const CustomError = class extends base {};
  CustomError.prototype.name = name;
  // Prevent the inevitable copy-paste bug
  if (name in errors)
    throw new Error(`Error class ${name} already exists`);
  return (errors[name] = CustomError);
}

// API Errors
const _Error = addErrorClass('Error');
export { _Error as Error };
export const FieldError = addErrorClass('FieldError', _Error);

function getError(url, params, res) {
  const { name, message, ...info } = res;
  // Instantiate the appropriate error class
  const error = new (errors[name] || errors['Error'])(message);
  // Set the name anyway if we don't know about this error
  if (!errors[name])
    error.name = name;
  // Copy any additional properties
  Object.assign(error, info);
  // Add properties for convenience
  error.params = params;
  error.url = url;
  return error;
}
```

This exports two separate error types - `api.Error`, the base class for all API
errors and `api.FieldError`, an error type for invalid data in form fields
which will have an additional `field` property.

You can now use the API like so:

```javascript
import * as api from './api';

async function main() {
  try {
    await api.post('/things', { name: 'My thing' });
  } catch (e) {
    if (!(e instanceof api.Error))
      throw e;
    console.error(`${e.name} at ${e.url}`);
    if (e instanceof api.FieldError)
      alert(`Invalid field "${e.field}" - ${e.message}`);
    else
      console.error(e.message);
  }
}

main();
```

You can easily add additional properties, such as the common `code`. You can
also have nested errors, eg. `FormError` with an `errors` property which is an
array of `FieldError`.
