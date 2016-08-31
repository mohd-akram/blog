#!/usr/bin/env python
# -*- coding: utf-8 -*- #
from __future__ import unicode_literals

THEME = 'themes/pelican-themes/pelican-bootstrap3'

AUTHOR = 'Mohamed Akram'
SITENAME = 'Dev Blog'
CC_LICENSE = 'CC-BY'

TIMEZONE = 'Asia/Dubai'

DEFAULT_LANG = 'en'

ARTICLE_SAVE_AS = '{date:%Y}/{date:%m}/{date:%d}/{slug}.html'
ARTICLE_URL = ARTICLE_SAVE_AS

# Feed generation is usually not desired when developing
FEED_ALL_ATOM = None
CATEGORY_FEED_ATOM = None
TRANSLATION_FEED_ATOM = None

# Blogroll
LINKS = ()

# Social widget
SOCIAL = (('github', 'https://github.com/mohd-akram'),)

DEFAULT_PAGINATION = 10

# Uncomment following line if you want document-relative URLs when developing
RELATIVE_URLS = True
