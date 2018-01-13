#!/bin/bash
# $1 year
rofi \
  -columns 3 \
  -lines 5 \
  -width 25 \
  -fixed-num-lines true \
  -modi "$1":"~/rofi-scripts/cal-year.sh $1" \
  -show
