---
title: Color-Coding Dots in CSS
---

I used this technique for a grid of images where I needed to color-code them,
possibly using more than one color for each image, without being too obtrusive.

Here's what it looks like:

<iframe frameborder="0" height="100" srcdoc='
<style>
.item {
  width: 60px;
  height: 60px;
  background-color: #eee;
  border-radius: 5px;
  display: inline-block;
  margin: 5px;
  padding-right: 5px;
  text-align: right;
}
.item.blue::before {
  content: "●";
  color: #0074D9;
}
.item.purple::after {
  content: "●";
  color: #B10DC9;
}
</style>
<div class="item blue"></div>
<div class="item purple"></div>
<div class="item blue purple"></div>
'></iframe>

```html
<div class="item blue"></div>
<div class="item purple"></div>
<div class="item blue purple"></div>
```

```css
.item.blue::before {
  content: "●";
  color: #0074D9;
}

.item.purple::after {
  content: "●";
  color: #B10DC9;
}
```

To add two dots without needing additional HTML elements, we use the
pseudo-elements `::before` and `::after` and set each one's `content` property
to `●`, the black circle Unicode character (U+25CF), which makes for a good
dot.

For three or more colors, we need a different approach:

<iframe frameborder="0" height="100" srcdoc='
<style>
.item {
  width: 60px;
  height: 60px;
  background-color: #eee;
  border-radius: 5px;
  display: inline-block;
  margin: 5px;
  padding-right: 5px;
  text-align: right;
}
.item::after {
  color: transparent;
  background-clip: text;
  -webkit-background-clip: text;
}
.item.green.blue.purple::after {
  content: "●●●";
  background-image: linear-gradient(
    to right, #2ECC40 33%, #0074D9 33%, #0074D9 67%, #B10DC9 67%
  );
}
</style>
<div class="item green blue purple"></div>
'></iframe>

```html
<div class="item green blue purple"></div>
```

```css
.item::after {
  color: transparent;
  background-clip: text;
  -webkit-background-clip: text;
}

.item.green.blue.purple::after {
  content: "●●●";
  background-image: linear-gradient(
    to right, #2ECC40 33%, #0074D9 33%, #0074D9 67%, #B10DC9 67%
  );
}
```

This time we use a single pseudo-element (`::after`) and set its content to
three dots instead of one. To color them, we use a `linear-gradient` with hard
stops placed just between each dot (at 33% and 67%), essentially faking three
separate solid colors. Since CSS gradients apply to backgrounds instead of
text, we use `background-clip: text` to apply it to the text dots instead. All
this because we can't use multiple `::after` pseudo-elements
[(yet)](http://realworldvalidator.com/css/pseudoelements/::after(2)).

You'll notice, however, that right now this only works for a single color
combination (green, blue, purple). If you only add one or two of those classes,
you'll get nothing. This is because every possible color combination (gradient)
needs to be specified. Since this can be very tedious, I wrote the following
Python script to automate it:

<!-- {% raw %} -->
```python
#!/usr/bin/env python3
import sys
from itertools import combinations

def gradient(*colors):
    g = []
    l = len(colors)
    for i, color in enumerate(colors):
        if i > 0:
            g.append(f'{color} {round(i * 100/l)}%')
        if i < l - 1:
            g.append(f'{color} {round((i+1) * 100/l)}%')
    return ', '.join(g)

prefix = sys.argv[1]
codes = [
    (n, c) for n, c in (a.split(':') for a in sys.argv[2:])
]

for i in range(1, len(codes) + 1):
    for combination in combinations(codes, i):
        classes, colors = zip(*combination)
        selector = ''.join(f'.{c}' for c in classes)
        dots = '●' * len(combination)
        background = (
            f'background-image: linear-gradient(to right, {gradient(*colors)})'
            if len(combination) > 1 else f'background-color: {colors[0]}'
        )
        print(
            f'{prefix}{selector}::after {{',
            f'  content: "{dots}";',
            f'  {background};',
            f'}}',
            sep='\n', end='\n\n'
        )
```
<!-- {% endraw %}) -->

To get the combinations used for my example, save the script as `dots-css` and
run it like so:

    dots-css .item green:#2ECC40 blue:#0074D9 purple:#B10DC9

If you've got N colors, this will generate 2<sup>N</sup> - 1 CSS rules, so keep
that in mind.
