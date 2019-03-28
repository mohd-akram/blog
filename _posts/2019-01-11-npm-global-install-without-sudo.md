---
title: npm Global Install Without sudo
description: The simplest way to install npm modules globally without sudo.
---

    npm config set prefix ~/.local
    echo 'PATH=~/.local/bin:$PATH' >> ~/.profile
