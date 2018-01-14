#!/bin/bash
# $1 year
rofi \
  -config ~/openbox-config/rofi-scripts/cal-config.rasi \
  -columns 3 \
  -lines 5 \
  -width 25 \
  -fixed-num-lines true \
  -modi "$1":"~/openbox-config/rofi-scripts/cal-year.sh $1" \
  -show
