#!/bin/bash
# $1 month in short abbreviation
# $2 year
rofi \
  -config ~/openbox-config/rofi-scripts/cal-config.rasi \
  -columns 7 \
  -lines 8 \
  -width 40 \
  -fixed-num-lines true \
  -modi "$1 $2":"~/openbox-config/rofi-scripts/cal-mon.sh $1 $2" \
  -show
