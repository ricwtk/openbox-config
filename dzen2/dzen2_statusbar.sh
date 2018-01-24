#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
font="Noto Sans:size=9"
boldfont="Noto Sans:bold:size=9"
smallfont="Noto Sans:size=9"
iconfont="FontAwesome:size=10"
padding="10"
left_pre=""
left_post=""
center_pre="^fn($boldfont)"
center_post="^fn()"
right_pre=""
right_post=""
bgColor="#263238"
fgColor="#ECEFF1"
alertColor="#F44336"
hiddenColor="#607D8B"
selectedBgColor="#607D8B"
# xftwidth from https://github.com/vixus0/xftwidth

# functions string
reload_dzen="$DIR/reload_dzen.sh"
volume="$DIR/volume.sh"
wm="$DIR/wm.sh"

# remove previously saved pid
rm -f /tmp/dzenpid

dateAndTime () {
  echo "^ca(1,$DIR/../rofi-scripts/rofi-cal-mon.sh $(date +%b\ %Y)) $(date +%H:%M\ \ %d\ %b\ %Y) ^ca();$(date +%H:%M\ \ %d\ %b\ %Y)"
}
volumeBlock () {
  local volText=""
  local volTextDummy=""
  local color="$fgColor"
  if [[ "$($volume isMuted)" = "yes" ]]
  then
    color="$hiddenColor"
  fi
  local volPerc="$($volume getVolume)"
  volTextDummy="█ $volPerc%"
  volText="^fn($iconfont)\u$( echo "obase=16;61478 + $volPerc/34" | bc )^fn() $volPerc^fn($smallfont)%^fn()"
  volText="^ca(4,$volume stepUp 1)$volText^ca()"
  volText="^ca(5,$volume stepDown 3)$volText^ca()"
  volText="^ca(1,$volume toggleMute)$volText^ca()"

  echo -e "^fg($color)$volText^fg();$volTextDummy"
}
desktopSelect () {
  local gap="^r(5x0)"
  local op="^ca(1, $wm removeDesktop)$gap-$gap^ca()"
  while IFS=" " read -a array
  do
    local name="\u$(echo "obase=16;ibase=16;03B1+${array[0]}" | bc)"
    if [[ "${array[1]}" = "*" ]]
    then
      op="$op^ca(1, $wm switchToD ${array[0]})^bg($selectedBgColor)$gap$name$gap^bg()^ca()"
    else
      op="$op^ca(1, $wm switchToD ${array[0]})$gap$name$gap^ca()"
    fi
  done <<< "$(wmctrl -d | sed "s/^\([0-9]*\ *[-*]\)\ .*$/\1/")"
  op="$op^ca(1, $wm addDesktop)$gap+$gap^ca()"
  op="^ca(4,$wm nextD)$op^ca()"
  op="^ca(5,$wm prevD)$op^ca()"
  echo -e "$op"
}

createOutput () {
  local left="$(desktopSelect)"
  local center=""
  local center_dummy=""
  while IFS=";" read -a array
  do
    center="$center${array[0]}"
    center_dummy="$center_dummy${array[1]}"
  done <<< "$(dateAndTime)"
  local center_offset="$(( $(xftwidth "$font" "$center_dummy")/2 ))"

  local right=""
  local right_dummy=""
  while IFS=";" read -a array
  do
    right="$right${array[0]}"
    right_dummy="$right_dummy${array[1]}"
  done <<< "$(volumeBlock)"
  local right_offset="$(( $(xftwidth "$font" "${right_dummy}x") + $padding ))"
  local op="^p(_LEFT)^p($padding)$left_pre$left$left_post \
  ^p(_CENTER)^p(-$center_offset)$center_pre$center$center_post \
  ^p(_RIGHT)^p(-$right_offset)$right_pre$right$right_post"
  echo -e "$op"

}

while read -r line
do
  linearray=($line)
  config=${linearray[2]}
  w="$(echo ${config} | sed 's/^\([0-9]*\)\/.*/\1/')"
  h="$(echo ${config} | sed 's/^.*x\([0-9]*\)\/.*/\1/')"
  x="$(echo ${config} | sed 's/^.*+\([0-9]*\)+.*/\1/')"
  y="$(echo ${config} | sed 's/^.*+\([0-9]*\)$/\1/')"
  (
    echo $BASHPID >> /tmp/dzenpid
    echo $BASHPID > /tmp/pid
    trap 'printf " "' SIGUSR1
    while true
    do
      echo -e "$(createOutput)"
      sleep 5 &
      wait $!
    done
  ) | dzen2 -ta l \
  -x "$x" \
  -y "$y" \
  -w $w \
  -h 20 \
  -fn "$font" \
  -bg "$bgColor" \
  -fg "$fgColor" \
  -e "button3=exec:kill -SIGUSR1 $(</tmp/pid);sigusr1=exec:kill -SIGUSR1 $(</tmp/pid);" &


  # -y "$(( $y+$h-20 ))" \ use this for bottom positioning
  # -dock is not working, alternatively use openbox margin to provide a "docking" style

  # conky -c $DIR/../conky/conky.lua | dzen2 -dock \
  # -ta l \
  # -x $x \
  # -y $y \
  # -w $w \
  # -h 30 \
  # -fn "$font" &
done <<< "$(xrandr --listactivemonitors | grep "^ [0-9]:")"
