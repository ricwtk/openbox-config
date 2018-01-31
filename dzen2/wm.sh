#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
reload_dzen="$DIR/reload_dzen.sh"

getNumberOfDesktop () {
  wc -l <<< "$(wmctrl -d)"
}
getCurrentDesktop () {
  wmctrl -d | grep "^[0-9]* *\*" | sed "s/^\([0-9]*\) .*$/\1/"
}

if [[ "$1" = "addDesktop" ]]
then
  wmctrl -n $(( $(getNumberOfDesktop) + 1 ))
elif [[ "$1" = "removeDesktop" ]]
then
  wmctrl -n $(( $(getNumberOfDesktop) - 1 ))
elif [[ "$1" = "switchToD" ]]
then
  wmctrl -s $2
elif [[ "$1" = "nextD" ]]
then
  cDesktop="$(getCurrentDesktop)"
  wmctrl -s "$(( $cDesktop==$(getNumberOfDesktop)-1 ? 0 : $cDesktop+1 ))"
elif [[ "$1" = "prevD" ]]
then
  cDesktop="$(getCurrentDesktop)"
  wmctrl -s "$(( $cDesktop==0 ? $(getNumberOfDesktop)-1 : $cDesktop-1 ))"
fi

# $reload_dzen
