#!/bin/bash
# $1 month in short abbreviation
# $2 year
rofi \
  -columns 7 \
  -lines 8 \
  -width 50 \
  -fixed-num-lines true \
  -modi "$1 $2":"~/rofi-scripts/cal-mon.sh $1 $2" \
  -show
