#!/bin/bash
# $1 month in short abbreviation
# $2 year
DIRPATH=~/Applications/openbox-config/rofi-scripts
rofi \
  -config $DIRPATH/cal-config.rasi \
  -columns 7 \
  -lines 8 \
  -width 50 \
  -fixed-num-lines true \
  -modi "$1 $2":"$DIRPATH/cal-mon.sh $1 $2" \
  -show
