#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
reload_dzen="$DIR/reload_dzen.sh"

isMuted () {
  pacmd list-sinks | cut -d "*" -f 2 | grep -P "^[\t *]muted:" | head -1 | cut -d ":" -f 2 | tr -d "[:space:]"
}
getCurrentSink () {
  pacmd list-sinks | grep -A999999999 "*" | grep -P "^[\t *]*index:" | cut -d ":" -f 2 | tr -d "[:space:]"
}
getFullVolumeValue () {
  pacmd list-sinks | grep -A999999999 "*" | grep -P "^[\t ]*volume steps:" | cut -d ":" -f 2 | tr -d "[:space:]"
}
getVolumeValue () {
  pacmd list-sinks | grep -A999999999 "*" | grep -P "^[\t ]*volume:" | cut -d ":" -f 3 | cut -d "/" -f 1 | tr -d "[:space:]"
}


if [[ "$1" = "isMuted" ]]
then
  isMuted
elif [[ "$1" = "toggleMute" ]]
then
  if [[ "$(isMuted)" = "yes" ]]
  then
    pacmd set-sink-mute "$(getCurrentSink)" no
  else
    pacmd set-sink-mute "$(getCurrentSink)" yes
  fi
elif [[ "$1" = "getVolume" ]]
then
  echo "$(getVolumeValue)*100/$(getFullVolumeValue)" | bc
elif [[ "$1" = "stepUp" ]]
then
  fullVolumeValue=$(getFullVolumeValue)
  newVol="$(echo $(getVolumeValue)+$fullVolumeValue*$2/100 | bc)"
  if [[ $newVol -gt $fullVolumeValue ]]
  then
    newVol=$fullVolumeValue
  fi
  pacmd set-sink-volume $(getCurrentSink) "$newVol"
elif [[ "$1" = "stepDown" ]]
then
  fullVolumeValue=$(getFullVolumeValue)
  newVol="$(echo $(getVolumeValue)-$fullVolumeValue*$2/100 | bc)"
  if [[ $newVol -lt "0" ]]
  then
    newVol=0
  fi
  pacmd set-sink-volume $(getCurrentSink) "$newVol"
fi

$reload_dzen
