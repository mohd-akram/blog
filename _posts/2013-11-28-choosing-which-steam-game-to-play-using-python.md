---
title: Choosing Which Steam Game to Play Using Python
description: >
  Using Python, Tk and the Steam API to create a simple app that helps you
  decide which Steam game to play in your growing library.
---

Introduction
------------

Steam sales are a wonderful thing and with the Autumn Sale going on now, a lot
of game libraries are going to grow larger by the end of it. For this reason, I
thought it might be a good idea to make a random Steam game chooser to give
some of those dusty, forgotten games in the games list a chance to be played.

Code
----

First, you're going to need a Steam API key which you can get from
[here](http://steamcommunity.com/dev/). You'll also need to know your 64-bit
Steam ID which you can find from [here](http://steamidconverter.com/). Make
sure you have the [Pillow (PIL)](https://pypi.python.org/pypi/Pillow) library
too. The code is fairly straightforward:

```python
import json
import random
import webbrowser
from urllib.request import urlopen
from urllib.error import HTTPError

from tkinter import Tk, Button
from PIL import ImageTk

apikey = ''
steamid = ''


def getownedgames(apikey, steamid):
    url = ('http://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/'
           '?key={}&steamid={}&include_appinfo=1'.format(apikey, steamid))

    return json.loads(urlopen(url).read().decode())['response']['games']


def getimage(game):
    imageurl = 'http://cdn.steampowered.com/v/gfx/apps/{}/header.jpg'
    data = urlopen(imageurl.format(game['appid'])).read()

    return ImageTk.PhotoImage(data=data)


def playgame(game):
    webbrowser.open('steam://rungameid/{}'.format(game['appid']))


def choosegame(games, tk, button):
    game = random.choice(games)

    try:
        game['image'] = getimage(game)
    except HTTPError:
        return choosegame(games, tk, button)

    button.configure(image=game['image'], command=lambda: playgame(game))

    tk.title(game['name'])

games = getownedgames(apikey, steamid)

# GUI
tk = Tk()
tk.resizable(0, 0)
tk.configure(bg='gray11')

gamebutton = Button(tk, width=460, height=215, bd=0,
                    bg='gray11', activebackground='gray11',
                    relief='flat', cursor='hand2')
gamebutton.pack()

changebutton = Button(tk, width=41, height=1, bd=0,
                      fg='white', activeforeground='white',
                      bg='gray11', activebackground='gray11',
                      relief='flat', cursor='hand2',
                      font=('Segoe UI Semilight',), text='Nope!',
                      command=lambda: choosegame(games, tk, gamebutton))
changebutton.pack()

changebutton.invoke()

tk.mainloop()
```

Explanation
-----------

The code sets up a Tk window with an image of the game acting as a link to play
it and a button underneath to find another random game. The `getownedgames`
function gets a list of the user's Steam games as a JSON object which is
converted to a dictionary using the `json.loads` function from the `json`
module. To open the game, the `webbrowser` module is used to open the Steam URL
of the game in the default handler.

Sometimes a game doesn't have an image which is why I have the try-except block
in the `choosegame` function. Also, the image is stored in the `game`
dictionary as we need to maintain a reference to any Tk images.

For the GUI, to make the window non-resizable, `tk.resizable(0, 0)` is called.
Each of the buttons is passed a function for the `command` argument which is
called when the button is pressed. Finally, the `choosegame` function is called
by invoking it through the second button.

Save the file with a `.pyw` extension to not show a console window.
