---
title: Will Software Engineering Survive?
description: Investigating recent claims amidst the rise of LLMs.
---

Since LLMs have been released, many claims about LLMs or in support of them
have left me scratching my head, and wondering if software engineering
principles were a myth all along.

Before LLMs, it was well accepted that lines of code written is not a measure
of productivity. Rather, the less code you have, the better, because it's
easier to review and maintain. This is all the more important for
network-facing and security-sensitive code, as it reduces the attack surface.
Nowadays, this has been forgotten or ignored. For example, the recently
released and very popular vibe-coded software OpenClaw is more than 800k lines
of code.

In cases where a lot of code is needed, due to the essential complexity of the
problem, the solution was to build a component, library or framework that was
well-tested and then used as a module. If the problem was common enough (which
is the case for most problems), it was published as open-source. For
infrastructure software, open-source has become practically mandatory.
Altogether, this reduced the work that needed to be done and focused efforts in
one place rather than having N versions of the same type of software with a
different set of bugs each. Since LLMs, this has gone out the window.
Duplication is now encouraged, and vibe coding a hundred differently buggy
closed-source versions of the same thing is fine.

Even if one were to accept that LLMs provide an immense productivity boost in
terms of writing code, that has never been a bottleneck of software
engineering. As Dijkstra said, "computer science is no more about computers
than astronomy is about telescopes". I would add to that "programming is no
more about coding", rather, it's about gathering and refining requirements,
thinking hard about architecture, the correct data structures, security,
deployment, and myriad other aspects. Any potential time-saving in writing the
code will quickly evaporate in the grand scheme of things, particularly in the
long run for any serious production project.

Before LLMs, programming was viewed as a deterministic endeavour described in a
precise language. Programming languages, and not English, were viewed as the
correct abstraction to improve clarity. Dijkstra (again)
[argued](https://www.cs.utexas.edu/~EWD/transcriptions/EWD06xx/EWD667.html)
against "natural language programming", while
[Lamport](https://en.wikipedia.org/wiki/Leslie_Lamport) argues in favor of even
more formalism. I suppose natural language programming is too tempting, but
thinking logically and symbolically is unavoidable whether in mathematics or
programming. The fewer programmers know it, the worse software will become.

Another striking phenomenon is the suggestion that LLMs be used for "grunt
work", such as tests. As some have argued, tests can be more important than the
code itself as they encode the desired behavior of a program. If any part
should be written by the human, it's the test, since only they would know
what's expected out of the program.

These are just some examples of software engineering principles that seem to
have been thrown out overnight. Some have justified this by saying that LLMs
are so revolutionary that we have to rethink software engineering altogether. I
find this hard to believe. Software engineering is rooted in formal concepts
from computer science and mathematics, theories including information theory,
complexity theory, systems theory, among others. These cannot be bypassed with
or without AI. Not to mention the physical limits regarding the immense
resource consumption of these models. When the calculator was introduced,
formal proofs and mathematical rigor did not go anywhere. Students still learn
to practice mathematics without a calculator, and I believe the same will
happen with software engineering once the craze dies down---if it's meant to
survive.
