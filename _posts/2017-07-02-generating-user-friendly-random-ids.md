---
title: Generating User-Friendly Random IDs
description: >
  A solution for generating short, user-friendly random IDs that are easy to
  pass around.
---

I stumbled upon the problem of generating short, user-friendly random IDs for a
web project. After looking at many existing solutions and not finding a
suitable one, I came up with this:

```javascript
// For production use, see NPM package below
function simpleId(length = 8, chars = "23456789abcdefghjkmnpqrstuvwxyz") {
  const numValues = chars.length ** length;
  const numBytes = Math.ceil(Math.log2(numValues) / 8);
  const randValues = 2 ** (numBytes * 8);

  const threshold = randValues % numValues;

  let randomNumber;
  const bytes = new Uint8Array(numBytes);
  do randomNumber = crypto.getRandomValues(bytes).reduce((n, b) => n * 256 + b);
  while (randomNumber < threshold);
  randomNumber %= numValues;

  let randomId = "";
  for (let i = randomNumber; i > 0; i = Math.trunc(i / chars.length))
    randomId = chars[i % chars.length] + randomId;
  randomId = randomId.padStart(length, chars[0]);

  return randomId;
}
```

This code generates an 8-character random ID with some useful properties.
First, it uses a case-insensitive, 31-character alphabet which consists of the
digits and lowercase letters while excluding `01ilo`. This significantly
reduces the possibility of transcription errors. Secondly, it uses the
cryptographically strong `crypto.getRandomValues()` function to reduce the
predictability of generated IDs. Lastly, it removes any modulo bias and returns
a random ID with the exact length specified.

I've created an [NPM package](https://www.npmjs.com/package/simple-id) which
contains the same code with error-checking and some tests. After installing it,
you can simply do:

```javascript
const simpleId = require('simple-id');
simpleId();
```
