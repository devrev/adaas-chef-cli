#!/bin/sh

# Check if user has bash
if [ -z "$BASH" ]; then
    echo "source $PWD/autocomplete/bash_autocomplete" >> ~/.bashrc
fi

# Check if user has zsh
if [ -z "$ZSH_NAME" ]; then
    echo "source $PWD/autocomplete/zsh_autocomplete" >> ~/.zshrc
fi
