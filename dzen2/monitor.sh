#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
reload_dzen="$DIR/reload_dzen.sh"

getActiveMons () {
  xrandr --listactivemonitors | sed "/^Monitors/d;s/.* \(.*\)$/\1/"
}
getBrightness () {
  local a="$(xrandr --verbose | sed -n "/$1/,/Brightness:/p" | sed -n "s/^[ \t]*Brightness: *\([0-9\.]*\) *$/\1/p")"
  echo "scale=0; $a*100/1" | bc
}
getOverallBrightness () {
  getBrightness "$(getActiveMons | sed "1!d")"
}
setAllBrightness () {
  while read -r mon
  do
    xrandr --output $mon --brightness $1
  done <<< "$(getActiveMons)"
}

if [[ "$1" = "overall" ]]
then
  getOverallBrightness
elif [[ "$1" = "dimAll" ]]
then
  setAllBrightness 0.5
elif [[ "$1" = "brightenAll" ]]
then
  setAllBrightness 1.0
elif [[ "$1" = "lightOffAll" ]]
then
  setAllBrightness 0.1
elif [[ "$1" = "stepUp" ]]
then
  allB="$(getOverallBrightness)"
  step="5"
  setAllBrightness "$(bc <<< "scale=2; $(( $allB+$step>100 ? 100 : $allB+$step ))/100")"
elif [[ "$1" = "stepDown" ]]
then
  allB="$(getOverallBrightness)"
  step="5"
  setAllBrightness "$(bc <<< "scale=2; $(( $allB-$step<10 ? 10 : $allB-$step ))/100")"
fi
