#!/bin/bash

if [[ $1 = "display" ]]
then
  echo -e "\uf120"
elif [[ $1 = "function" ]]
then
  x-terminal-emulator
fi
