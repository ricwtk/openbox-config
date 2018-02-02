#!/bin/bash

if [[ $1 = "display" ]]
then
  echo -e "\uf141"
elif [[ $1 = "function" ]]
then
  rofi -show
fi
