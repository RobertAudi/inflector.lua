#!/usr/bin/env bash

if [[ "$1" == "luajit" ]] && command -v luajit 1> /dev/null 2> /dev/null; then
  luajit ./tests.lua
elif [[ "$1" == "all" ]]; then
  lua ./tests.lua

  if command -v luajit 1> /dev/null 2> /dev/null; then
    echo "\n"
    luajit ./tests.lua
  fi
else
  lua ./tests.lua
fi
