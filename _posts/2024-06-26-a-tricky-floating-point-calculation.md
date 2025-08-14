---
title: A Tricky Floating-Point Calculation
description: >
  Figuring out why a seemingly simple floating-point calculation returned a
  very wrong result.
math: yes
---

I was working on my [simple-id](https://www.npmjs.com/package/simple-id)
library and was curious about [different
methods](https://www.pcg-random.org/posts/bounded-rands.html) to generate an
unbiased random number in a given range. As a way to test whether a random
number generator (RNG) produces good results, one can calculate the expected
number of repeats based on the [birthday
problem](https://en.wikipedia.org/wiki/Birthday_problem) and compare it with
the output of the RNG. The formula can be found online in several places as it
can also be used for [counting expected hash
collisions](https://matt.might.net/articles/counting-hash-collisions/) or cache
hits. The expected number of repeats can be calculated as follows:

$$ n - d + d \left( \frac{d-1}{d} \right)^n $$

Where $$n$$ is the number of generated values and $$d$$ is the range.

Converting this to JavaScript code:

```javascript
function repeats(n, d) {
  return n - d + d * ((d - 1) / d)**n;
}
```

In my case, I wanted to check the expected repeats after generating a million
random IDs, where each ID is 8 characters long and there are 31 characters in
the alphabet. That is, $$n=10^6$$ and $$d=31^8$$. Running this in JavaScript:

```javascript
console.log(repeats(1e6, 31**8));
```

The result is -19.72998046875.

Wait, what? Negative repeats? I've known about the infamous `0.1 + 0.2`
inaccuracy, but this is different; it's a much larger error, and from only a
handful of operations. I double (and triple) checked that I typed the formula
correctly, and tried it in both C and Python and got the same result. I then
put it into
[WolframAlpha](https://www.wolframalpha.com/input?i=n%3D1e6%3B+d%3D31**8%3B+n+-+d+%2B+d+*+%28%28d+-+1%29+%2F+d%29**n),
since it supports arbitrary precision, and it returned something longer, but
much more sensible:

> <small>0.5862405426220060595736096268572069594630842175323822481323009</small>

That seemed right. I started tweaking the formula to try to get rid of the
error. I figured that, most likely, the division leads to a loss of accuracy
that's exacerbated by raising to a very high power. To avoid this, I reached
for `BigInt` to calculate the power of the numerator and denominator
separately, then divide. Since `BigInt` only supports integers, I also multiply
by a "precision" before converting to a number, then divide by it after to get
a decimal value:

```javascript
function repeats(n, d) {
  const p = n*d;
  const e = Number(BigInt(p) * BigInt(d-1)**BigInt(n) / BigInt(d)**BigInt(n))/p;
  return n - d + d * e;
}
```

That returns **0.586**3037109375. On the one hand, the result is correct to
three significant figures, which is an improvement over the previous zero. On
the other, this takes a second and a half to finish computing. After trying a
few different things, I got a tip from a user on the
[##math](https://libera-math.github.io) IRC channel to try `log1p` for the
calculation. What does `log` have to do with anything? The way computers
calculate the power is like so:

$$ x^n = e^{\left( n \log{x} \right)} $$

So we can rewrite the formula to:

$$ n - d + d \exp{\left( n \log{\frac{d-1}{d}} \right)} $$

The `log1p` function returns the result of $$\log{\left(1 + x\right)}$$. The
reason it exists is because floating-point does not work well when adding a
small $$x$$ to $$1$$. Since $$d$$ is very large, this is the case in our
formula. We can rewrite the expression to make it usable in `log1p`:

$$ n - d + d \exp{\left( n \log{\left( 1 - \frac{1}{d} \right)} \right)} $$

The code then becomes:

```javascript
function repeats(n, d) {
  return n - d + d * Math.exp(n * Math.log1p(-1 / d));
}
```

Running it returns **0.586**3037109375, the same value as using `BigInt`, only
now it doesn't take a second and a half to calculate. However, it still wasn't
as accurate as I'd like. While looking into this, I came across another
function that also works better for small values, `expm1`, which returns
$$e^x - 1$$. We can factor out $$d$$ to make this usable too:

$$ n + d \left( \exp{\left( n \log{\left( 1 - \frac{1}{d} \right)} \right)} - 1 \right) $$

And in code:

```javascript
function repeats(n, d) {
  return n + d * Math.expm1(n * Math.log1p(-1 / d));
}
```

Running this, we get **0.586240542**3540622, a much improved result accurate to
nine significant figures. This was as good as it was going to get in
JavaScript.

Out of curiosity, I wanted to see if a better result was possible using C,
since it provides yet another function for preserving accuracy, `fma`, also
known as fused multiply and add. Rather than lose accuracy twice on both the
multiplication and the addition, rounding only happens once after the
calculation when using `fma`. It also happens to be faster, since it uses a
single native CPU instruction for both operations. C also provides the `long
double` type, which is as precise as a `double` or more, depending on the
implementation. On my machine, `sizeof(long double)` returns 16, i.e. it is a
128-bit floating-point number, also known as a quad. Trying them both out:

```c
double repeats(double n, double d)
{
	return fma(d, expm1(n * log1p(-1 / d)), n);
}

long double repeatsl(long double n, long double d)
{
	return fma(d, expm1l(n * log1pl(-1 / d)), n);
}
```

This yields **0.586240542**40892864431 and **0.586240542**58953528507,
respectively, with a very slight improvement in accuracy, but still only
accurate to nine significant figures. At this point, I was out of my depth. I
tried the [Herbie](https://herbie.uwplse.org) project which automatically
rewrites floating-point expressions and it gave some good results but the
suggestions were rather unwieldy. Let me know if you can find another way to
compute this with better accuracy --- perhaps there is yet another trick
floating out there.
