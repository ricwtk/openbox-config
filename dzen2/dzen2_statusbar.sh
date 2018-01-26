#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
font="Noto Sans:size=9"
boldfont="Noto Sans:bold:size=9"
smallfont="Noto Sans:size=6"
iconfont="FontAwesome:size=10"
padding="10"
left_pre=""
left_post=""
center_pre=""
center_post=""
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
monitor="$DIR/monitor.sh"
calendar="$DIR/../rofi-scripts/rofi-cal-mon.sh $(date +%b\ %Y)"

# remove previously saved pid
rm -f /tmp/dzenpid

# format of the output of a block: <output>;<boldfont text>;<font text>;<smallfont text>;<iconfont text>;<extra padding>
gap="^r(10x0)"
gapsize2="23"

dateAndTime () {
  local displayFormat="%H:%M  %a  %d %b %Y"
  local op="$(date +"$displayFormat")"
  op="^ca(1,$calendar)$op^ca()"
  op="^fn($boldfont)$op^fn()"
  echo -e "$op;$(date +"$displayFormat");;;;0"
}
desktopSelect () {
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
terminal () {
  local op="^ca(1,x-terminal-emulator)$gap^fn($iconfont)\uf120^fn()$gap^ca()"
  echo -e "$op;;;;\uf120;$gapsize2"
}
spacer () {
  echo -e "^r(10x0);;;;;15"
}
more () {
  local op="^ca(1,rofi -show ⚙)$gap^fn($iconfont)\uf141^fn()$gap^ca()"
  echo -e "$op;;;;\uf141;$gapsize2"
}
reload () {
  local op="^ca(1,$reload_dzen)$gap^fn($iconfont)\uf021^fn()$gap^ca()"
  echo -e "$op;;;;\uf021;$gapsize2"
}
applications () {
  local op="^ca(1,rofi -show drun)$gap^fn($iconfont)\uf17c^fn()$gap^ca()"
  echo -e "$op;;;;\uf17c;$gapsize2"
}
windows () {
  local op="^ca(1,rofi -show window)$gap^fn($iconfont)\uf2d2^fn()$gap^ca()"
  echo -e "$op;;;;\uf2d2;$gapsize2"
}
volumeBlock () {
  local color="$fgColor"
  if [[ "$($volume isMuted)" = "yes" ]]
  then
    color="$hiddenColor"
  fi
  local volPerc="$($volume getVolume)"
  local icon="\u$( echo "obase=16;61478 + $volPerc/34" | bc )"
  local op="$gap^fn($iconfont)$icon^fn() $volPerc^fn($smallfont)%^fn()$gap"
  op="^ca(4,$volume stepUp 1)$op^ca()"
  op="^ca(5,$volume stepDown 3)$op^ca()"
  op="^ca(1,$volume toggleMute)$op^ca()"
  op="^fg($color)$op^fg()"

  echo -e "$op;; $volPerc;%;$icon;$gapsize2"
}
batteryBlock () {
  local isPluggedIn="$(upower -i `upower -e | grep "AC"` | grep "online" | sed "s/^.*: *\([a-z]*\) */\1/")"
  local batPerc="$(upower -i `upower -e |grep "BAT"` | grep "percentage" | sed "s/^.*: *\([0-9]*\)% */\1/")"
  if [[ "$isPluggedIn" = "yes" ]]
  then
    local icon="\uf1e6"
  else
    local icon="\u$(echo "obase=16;62020-$batPerc/20.5" | bc)"
  fi
  local color="$fgColor"
  if [[ $batPerc -lt 15 ]]
  then
    color="$alertColor"
  fi
  local op="$gap^fg($color)^fn($iconfont)$icon^fn() $batPerc^fn($smallfont)%^fn()^fg()$gap"

  echo -e "$op;; $batPerc;%;$icon;$gapsize2"
}
networkBlock () {
  local ethernetState="$(nmcli device | grep "^[a-zA-Z0-9]* *ethernet" | sed "s/^[a-zA-Z0-9]* *[a-zA-Z0-9]* *\([a-zA-Z]*\) *.*$/\1/")"
  local wifiState="$(nmcli device | grep "^[a-zA-Z0-9]* *wifi" | sed "s/^[a-zA-Z0-9]* *[a-zA-Z0-9]* *\([a-zA-Z]*\) *.*$/\1/")"
  local color="$fgColor"
  if [[ "$ethernetState" = "connected" ]]
  then
    local icon="\uf0e8"
  elif [[ "$wifiState" = "connected" ]]
  then
    local icon="\uf1eb"
  else
    local icon="\uf0e8"
    color="$hiddenColor"
  fi
  local op="$gap^fg($color)^fn($iconfont)$icon^fn()^fg()$gap"

  echo -e "$op;;;;$icon;$gapsize2"
}
brightnessBlock () {
  local brightness="$($monitor overall)"
  local icons=("\uf005" "\uf123" "\uf006")
  local actions=("dimAll" "brightenAll" "lightOffAll")
  local s="$(( $brightness/34 ))"

  local op="$gap^fn($iconfont)${icons[$s]}^fn() $brightness^fn($smallfont)%^fn()$gap"
  op="^ca(1,$monitor ${actions[$s]})$op^ca()"
  op="^ca(3,$monitor ${actions[$(( ($s+1)%3 ))]})$op^ca()"
  op="^ca(4,$monitor stepUp)$op^ca()"
  op="^ca(5,$monitor stepDown)$op^ca()"

  echo -e "$op;; $brightness;%;$icon;$gapsize2"
}
keyboardBlock () {
  local icon="\uf11c"
  local thisEngine="$(ibus engine)"
  local big="$(sed "s/^.*:\([a-z]*\)$/\1/" <<< "$thisEngine")"
  big=${big:0:2}
  big=${big^^}
  local small="$(sed "s/^[a-z]*:\([a-z]*\):.*$/\1/" <<< "$thisEngine")"
  small=${small:0:2}
  small=${small^^}
  local allEngines
  read -a allEngines <<< $(ibus read-config | sed -n "s/.*engines-order.*\[\(.*\)\]/\1/p" | sed -e "s/[',]//g")
  allEngines=($(printf "%s\n" "${allEngines[@]}" | sort))
  local thisIdx=$(( $(printf "%s\n" "${allEngines[@]}" | grep -n "^$thisEngine$" | sed "s/:$thisEngine//") - 1 ))
  local nextIdx=$(( ($thisIdx+1)==${#allEngines[@]} ? 0 : $thisIdx+1 ))
  local prevIdx=$(( ($thisIdx-1)<0 ? ${#allEngines[@]}-1 : $thisIdx-1 ))
  local op="$gap^fn($iconfont)$icon^fn() $big ^fn($smallfont)$small^fn()$gap"
  op="^ca(1,ibus engine ${allEngines[$nextIdx]} & $reload_dzen)$op^ca()"
  op="^ca(3,ibus engine ${allEngines[$prevIdx]} & $reload_dzen)$op^ca()"

  echo -e "$op;; $big;$small;$icon;$gapsize2"
}


createOutput () {
  local left
  local left_dummy
  for l in applications spacer terminal spacer desktopSelect spacer windows spacer reload
  do
    while IFS=";" read -a array
    do
      left="$left${array[0]}"
      left_dummy="$left_dummy${array[1]}"
    done <<< "$($l)"
  done

  local center
  local center_offset
  local center_boldtext
  local center_text
  local center_smalltext
  local center_icons
  local center_padding=0
  for c in dateAndTime
  do
    while IFS=";" read -a array
    do
      center="$center${array[0]}"
      center_boldtext="$center_boldtext${array[1]}"
      center_text="$center_text${array[2]}"
      center_smalltext="$center_smalltext${array[3]}"
      center_icons="$center_icons${array[4]}"
      center_padding="$(( $center_padding + ${array[5]} ))"
    done <<< "$($c)"
  done

  center_offset="$(( $center_offset + $(xftwidth "$boldfont" "$center_boldtext") ))"
  center_offset="$(( $center_offset + $(xftwidth "$font" "$center_text") ))"
  center_offset="$(( $center_offset + $(xftwidth "$smallfont" "$center_smalltext") ))"
  center_offset="$(( $center_offset + $(xftwidth "$iconfont" "$center_icons") ))"
  center_offset="$(( $center_offset + $center_padding ))"
  center_offset="$(( $center_offset / 2 ))"

  local right
  local right_offset
  local right_boldtext
  local right_text
  local right_smalltext
  local right_icons
  local right_padding=0
  for r in keyboardBlock volumeBlock brightnessBlock batteryBlock networkBlock more
  do
    while IFS=";" read -a array
    do
      right="$right${array[0]}"
      right_boldtext="$right_boldtext${array[1]}"
      right_text="$right_text${array[2]}"
      right_smalltext="$right_smalltext${array[3]}"
      right_icons="$right_icons${array[4]}"
      right_padding="$(( $right_padding + ${array[5]} ))"
    done <<< "$($r)"
  done
  right_offset="$(( $right_offset + $(xftwidth "$boldfont" "$right_boldtext") ))"
  right_offset="$(( $right_offset + $(xftwidth "$font" "$right_text") ))"
  right_offset="$(( $right_offset + $(xftwidth "$smallfont" "$right_smalltext") ))"
  right_offset="$(( $right_offset + $(xftwidth "$iconfont" "$right_icons") ))"
  right_offset="$(( $right_offset + $right_padding ))"
  right_offset="$(( $right_offset + $padding ))"

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
      sleep 30 &
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
  -e "button3=exec:kill -SIGUSR1 $(</tmp/pid);sigusr1=exec:kill -SIGUSR1 $(</tmp/pid);onexit=exec:rm -f /tmp/dzenpid,exit:13" &


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
