#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [[ $1 = "display" ]]
then
  date +"%H:%M  %a  %d %b %Y"
elif [[ $1 = "function" ]]
then
  $DIR/../rofi-scripts/rofi-cal-mon.sh $(date +%b\ %Y)
fi
