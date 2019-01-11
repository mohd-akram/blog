---
title: npm Global Install Without sudo
---

    npm config set prefix ~/.local
    echo 'PATH=~/.local/bin:$PATH' >> ~/.profile
