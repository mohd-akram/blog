---
title: Generating User-Friendly Random IDs
---

I stumbled upon the problem of generating short, user-friendly random IDs for a
web project. After looking at many existing solutions and not finding a
suitable one, I came up with this:

```javascript
// For production use, see NPM package below
const crypto = require('crypto');

function simpleId(length = 8, chars = '23456789abcdefghjkmnpqrstuvwxyz') {
  const defaultChars = '0123456789abcdefghijklmnopqrstuvwxyz';

  const numValues = chars.length ** length;
  const numBytes = Math.ceil(Math.log2(numValues) / 8);
  const randValues = 2 ** (numBytes * 8);

  const threshold = randValues - (randValues % numValues);

  do {
    const bytes = crypto.randomBytes(numBytes);
    var randomNumber = parseInt(bytes.toString('hex'), 16);
  } while (randomNumber >= threshold);

  randomNumber %= numValues;

  const randomId = randomNumber.toString(chars.length).replace(
    /./g, m => chars[defaultChars.indexOf(m)]
  ).padStart(length, chars[0]);

  return randomId;
}
```

This code generates an 8-character random ID with some useful properties.
First, it uses a case-insensitive, 31-character alphabet which consists of the
digits and lowercase letters while excluding `01ilo`. This significantly
reduces the possibility of transcription errors. Secondly, it uses the
cryptographically strong `crypto.randomBytes()` function to reduce the
predictability of generated IDs. Lastly, it removes any modulo bias and returns
a random ID with the exact length specified.

I've created an [NPM package](https://www.npmjs.com/package/simple-id) which
contains the same code with error-checking and some tests. After installing it,
you can simply do:

```javascript
const simpleId = require('simple-id');
simpleId();
```
