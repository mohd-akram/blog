---
title: JavaScript Generator Gotchas
---

I've been using JavaScript generators in Node recently and discovered some
surprising behaviors.

Resuming generators
-------------------

Sometimes we wish to partially consume a generator and continue using it
elsewhere. The following code initializes a generator and uses it in a for-loop
before breaking immediately. Therefore, only the first item of the generator
(0) should be consumed. The next lines then iterate through the rest of the
generator where they should print the remaining items, i.e. the numbers 1 to 9.

```javascript
function* loop() {
  for (let i = 0; i < 10; i++)
    yield i;
}

const gen = loop();

for (const i of gen)
  break;

// Is this generator done?
// console.log(gen.next().done);

for (const i of gen)
  console.log(i);
```

However, this isn't the case. Once a generator is used in a for-loop, it seems
to be fully consumed somehow, regardless of a break statement. This can be
confirmed by manually inspecting the generator via checking the `done` property
on `gen.next()` after the first for-loop.

Finding this behavior odd, I tried the same code in Python:

```python
def loop():
    for i in range(10):
        yield i

gen = loop()

for i in gen:
    break

for i in gen:
    print(i)
```

In Python, the numbers 1 to 9 are printed as expected.

### Workaround

There's a way to fix this in JavaScript, which is to manually call `next` on
the generator in the first loop:

```javascript
let res;
while (!(res = gen.next()).done) {
  const { value } = res;
  break;
}
```

Not as pretty, however.

Alternatively, you can prevent the generator from being marked as done with the
following:

```javascript
function* loop() {
  for (let i = 0; i < 10;) {
    try {
      yield i;
      ++i;
    } finally {
      continue;
    }
  }
}
```

As a commenter explained below, the reason a generator is marked as done after
its use in a for-loop is to allow for cleanup to happen. In doing so, the
`finally` clause is always executed. By wrapping our yield statement in a
try-finally and using a `continue` statement, we make sure the loop is not
exited prematurely. Keep in mind that the increment must be moved directly
after the yield statement to prevent the generator from skipping a value. This
happens when there's a break in the for-loop and execution jumps to the finally
clause directly.

Async generators
----------------

I wanted to create a nice async `read()` function for iterating through
characters in a large text file in a convenient way. Well, what better way than
using an async generator! It would be used like this:

```javascript
for await (const [i, char] of read(filename))
  console.log(char);
```

Everything worked great, until I started doing some profiling and noticed that
performance was kind of bad. After doing a bit of searching I found that
[someone had already written about this 8 months
ago](https://medium.com/netscape/async-iterators-these-promises-are-killing-my-performance-4767df03d85b)
for an essentially identical use case.

I wanted to do my own test to confirm if this was still the case or if the
bottleneck was elsewhere and used the following code:

```javascript
function* loop() {
  for (let i = 0; i < 1e6; i++)
    yield i;
}

async function* loop2() {
  for (let i = 0; i < 1e6; i++)
    yield i;
}

async function main() {
  console.time('loop'); for (const i of loop()) ;
  console.timeEnd('loop');
  console.time('loop2'); for await (const i of loop2()) ;
  console.timeEnd('loop2');
}

main();
```

It turns out simply adding the `async` keyword to a generator is enough to make
it 10x slower, even if there is no async code in it.

Once again, I went to Python to see what the situation was there:

```python
import asyncio
import time

def loop():
    for i in range(int(1e6)):
        yield i

async def loop2():
    for i in range(int(1e6)):
        yield i

async def main():
    t0 = time.perf_counter()
    for i in loop():
        pass
    print('loop:', time.perf_counter() - t0)
    t0 = time.perf_counter()
    async for i in loop2():
        pass
    print('loop2:', time.perf_counter() - t0)

asyncio.get_event_loop().run_until_complete(main())
```

The async version is 2x slower in this case.

### Workaround

Stick to non-async generators for now until the performance situation improves.
