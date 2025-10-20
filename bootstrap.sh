#!/bin/bash

echo "Installing Devbox..."
curl -fsSL https://get.jetify.com/devbox | bash

echo "Installing Nushell via devbox global..."
devbox global add nushell

echo "Cloning Simon CLI from GitHub..."
mkdir "$HOME/repos"
git clone https://github.com/simon/simon-cli "$HOME/repos/simon-cli"

echo "Running simon bootstrap via nushell..."
nu -c "$HOME/repos/simon-cli/simon bootstrap"
