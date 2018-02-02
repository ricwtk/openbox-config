#!/bin/bash

if [[ $1 = "display" ]]
then
  echo -e "\uf17c"
elif [[ $1 = "function" ]]
then
  rofi -show drun
fi
