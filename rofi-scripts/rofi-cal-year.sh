#!/bin/bash
# $1 year
DIRPATH=~/Applications/openbox-config/rofi-scripts
rofi \
  -config $DIRPATH/cal-config.rasi \
  -columns 3 \
  -lines 5 \
  -width 25 \
  -fixed-num-lines true \
  -modi "$1":"$DIRPATH/cal-year.sh $1" \
  -show
