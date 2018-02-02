#!/bin/bash
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
display () {
  local volPerc="$(bc <<< "$(getVolumeValue)*100/$(getFullVolumeValue)")"
  local icon="\u$( echo "obase=16;61478 + $volPerc/34" | bc )"
  local op="<span font_desc='FontAwesome 10'>$icon</span> <span size='x-small'>$volPerc%</span>"
  if [[ "$(isMuted)" = "yes" ]]
  then
    op="<span foreground='#607D8B'>$op</span>"
  fi
  echo -e $op
}

if [[ $1 = "display" ]]
then
  echo $(display)
  pactl subscribe | grep --line-buffered "sink" | while read i; do echo $(display); done
elif [[ $1 = "toolTip" ]]
then
  echo "volume"
elif [[ $1 = "stepUp" ]]
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
elif [[ "$1" = "toggleMute" ]]
then
  if [[ "$(isMuted)" = "yes" ]]
  then
    pacmd set-sink-mute "$(getCurrentSink)" no
  else
    pacmd set-sink-mute "$(getCurrentSink)" yes
  fi
fi
