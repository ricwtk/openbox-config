#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
font="Noto Sans:size=9"
boldfont="Noto Sans:bold:size=9"
smallfont="Noto Sans:size=6"
iconfont="FontAwesome:size=10"
padding="10"
panelHeight="25"
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
bat_acConnectedMsg="🔌  AC connected"
bat_acDisconnectedMsg="🔋  AC disconnected"
bat_warnLevel="15"
workspace_color_cycle=("#EA80FC" "#FF8A80" "#8C9EFF" "#CCFF90" "#FFD180" "#CFD8DC")

# xftwidth from https://github.com/vixus0/xftwidth

# functions string
reload_dzen="$DIR/reload_dzen.sh"
volume="$DIR/volume.sh"
wm="$DIR/wm.sh"
monitor="$DIR/monitor.sh"
calendar="$DIR/../rofi-scripts/rofi-cal-mon.sh $(date +%b\ %Y)"

# filenames
f_pid="/tmp/dzenpid"
f_c_pid="/tmp/pid"
f_change="/tmp/dzenchange"

# remove previously saved pid
rm -f $f_pid
rm -f $f_change
touch $f_change

# format of the output of a block: <output>;<boldfont text>;<font text>;<smallfont text>;<iconfont text>;<extra padding>
gap="^r(10x0)"
gapsize2="23"

init=1

dateAndTime () {
  local displayFormat="%H:%M  •  %a  •  %d %b"
  local op="$(date +"$displayFormat")"
  op="^ca(1,$calendar)$op^ca()"
  op="^fn($boldfont)$op^fn()"
  if [[ $init = "1" ]]
  then
    coproc dzen2_dateAndTime ( while true; do sleep 30; echo "dateAndTime" >> $f_change; $reload_dzen; done )
  fi
  echo -e "$op;$(date +" %H:%M |  %a %d %b %Y");;;\uf017\uf073;0"
}
desktopSelect () {
  local op="^ca(1, $wm removeDesktop)$gap-$gap^ca()"
  while IFS=" " read -a array
  do
    # local name="\u$(echo "obase=16;ibase=16;03B1+${array[0]}" | bc)"
    local fgColor="${workspace_color_cycle[ $(( ${array[0]}%${#workspace_color_cycle[@]} )) ]}"
    if [[ "${array[1]}" = "*" ]]
    then
      # op="$op^ca(1, $wm switchToD ${array[0]})^bg($selectedBgColor)$gap$name$gap^bg()^ca()"
      op="$op^ca(1, $wm switchToD ${array[0]})^bg($selectedBgColor)^fg($fgColor)$gap\u25A0$gap^fg()^bg()^ca()"
    else
      op="$op^ca(1, $wm switchToD ${array[0]})^fg($fgColor)$gap\u25A1$gap^fg()^ca()"
    fi
  done <<< "$(wmctrl -d | sed "s/^\([0-9]*\ *[-*]\)\ .*$/\1/")"
  op="$op^ca(1, $wm addDesktop)$gap+$gap^ca()"
  op="^ca(4,$wm nextD)$op^ca()"
  op="^ca(5,$wm prevD)$op^ca()"
  if [[ $init = "1" ]]
  then
    coproc dzen2_desktopSelect ( xprop -root -spy | grep --line-buffered -e "^_NET_CURRENT_DESKTOP" -e "^_NET_NUMBER_OF_DESKTOPS" | while read i; do echo "desktopSelect" >> $f_change; $reload_dzen; done )
  fi
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
  local op="^ca(1,echo "all" >> $f_change && $reload_dzen)$gap^fn($iconfont)\uf021^fn()$gap^ca()"
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
  if [[ $init = "1" ]]
  then
    coproc dzen2_volumeBlock ( pactl subscribe | grep --line-buffered "sink" | while read i; do echo "volumeBlock" >> $f_change; $reload_dzen; done )
  fi
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
  if [[ $batPerc -lt $bat_warnLevel && "$isPluggedIn" = "no" ]]
  then
    color="$alertColor"
    notify-send "Battery low ($batPerc %)" -u critical
  fi
  local op="$gap^fg($color)^fn($iconfont)$icon^fn() $batPerc^fn($smallfont)%^fn()^fg()$gap"
  if [[ $init = "1" ]]
  then
    coproc dzen2_batteryBlock_1 ( upower -m | grep --line-buffered -e "AC" -e "BAT" | while read i; do echo "batteryBlock" >> $f_change; $reload_dzen; done )

    coproc dzen2_batteryBlock_2 ( upower -m | grep --line-buffered "daemon changed" | while read i
      do 
        isPluggedIn="$(upower -i `upower -e | grep "AC"` | grep "online" | sed "s/^.*: *\([a-z]*\) */\1/")"
        if [[ $isPluggedIn = "yes" ]]
        then
          notify-send "$bat_acConnectedMsg"
        else
          notify-send "$bat_acDisconnectedMsg"
        fi
        echo "batteryBlock" >> $f_change
        $reload_dzen
      done )
  fi
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
  if [[ $init = "1" ]]
  then
    coproc dzen2_networkBlock ( nmcli m | while read i; do echo "networkBlock" >> $f_change; $reload_dzen; done )
  fi
  echo -e "$op;;;;$icon;$gapsize2"
}
brightnessBlock () {
  local brightness="$($monitor overall)"
  local icons=("\uf005" "\uf123" "\uf006")
  local actions=("dimAll" "brightenAll" "lightOffAll")
  local s="$(( $brightness/34 ))"

  local op="$gap^fn($iconfont)${icons[$s]}^fn() $brightness^fn($smallfont)%^fn()$gap"
  op="^ca(1,$monitor ${actions[$s]} && echo "brightnessBlock" >> $f_change && $reload_dzen)$op^ca()"
  op="^ca(3,$monitor ${actions[$(( ($s+1)%3 ))]} && echo "brightnessBlock" >> $f_change && $reload_dzen)$op^ca()"
  op="^ca(4,$monitor stepUp && echo "brightnessBlock" >> $f_change && $reload_dzen)$op^ca()"
  op="^ca(5,$monitor stepDown && echo "brightnessBlock" >> $f_change && $reload_dzen)$op^ca()"
  if [[ $init = "1" ]]
  then
    coproc dzen2_brightnessBlock ( 
      brightness="$($monitor overall)"
      while true
      do 
        newBrightness="$($monitor overall)"
        if [[ "$brightness" != "$newBrightness" ]]
        then
          echo "brightnessBlock" >> $f_change; $reload_dzen; 
          brightness=$newBrightness
        fi
        sleep .5;
      done )
  fi
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
  op="^ca(1,ibus engine ${allEngines[$nextIdx]} & echo "keyboardBlock" >> $f_change & $reload_dzen)$op^ca()"
  op="^ca(3,ibus engine ${allEngines[$prevIdx]} & echo "keyboardBlock" >> $f_change & $reload_dzen)$op^ca()"
  if [[ $init = "1" ]]
  then
    coproc dzen2_keyboardBlock ( 
      thisEngine="$(ibus engine)"
      while true
      do 
        newEngine="$(ibus engine)"
        if [[ "$thisEngine" != "$newEngine" ]]
        then
          echo "keyboardBlock" >> $f_change; $reload_dzen; 
          thisEngine=$newEngine
        fi
        sleep .5;
      done )
  fi
  echo -e "$op;; $big;$small;$icon;$gapsize2"
}


# createOutput () {
#   local left
#   local left_dummy
#   for l in applications spacer terminal spacer desktopSelect spacer windows spacer reload
#   do
#     while IFS=";" read -a array
#     do
#       left="$left${array[0]}"
#       left_dummy="$left_dummy${array[1]}"
#     done <<< "$($l)"
#   done

#   local center
#   local center_offset
#   local center_boldtext
#   local center_text
#   local center_smalltext
#   local center_icons
#   local center_padding=0
#   for c in dateAndTime
#   do
#     while IFS=";" read -a array
#     do
#       center="$center${array[0]}"
#       center_boldtext="$center_boldtext${array[1]}"
#       center_text="$center_text${array[2]}"
#       center_smalltext="$center_smalltext${array[3]}"
#       center_icons="$center_icons${array[4]}"
#       center_padding="$(( $center_padding + ${array[5]} ))"
#     done <<< "$($c)"
#   done

#   center_offset="$(( $center_offset + $(xftwidth "$boldfont" "$center_boldtext") ))"
#   center_offset="$(( $center_offset + $(xftwidth "$font" "$center_text") ))"
#   center_offset="$(( $center_offset + $(xftwidth "$smallfont" "$center_smalltext") ))"
#   center_offset="$(( $center_offset + $(xftwidth "$iconfont" "$center_icons") ))"
#   center_offset="$(( $center_offset + $center_padding ))"
#   center_offset="$(( $center_offset / 2 ))"

#   local right
#   local right_offset
#   local right_boldtext
#   local right_text
#   local right_smalltext
#   local right_icons
#   local right_padding=0
#   for r in keyboardBlock volumeBlock brightnessBlock batteryBlock networkBlock more
#   do
#     while IFS=";" read -a array
#     do
#       right="$right${array[0]}"
#       right_boldtext="$right_boldtext${array[1]}"
#       right_text="$right_text${array[2]}"
#       right_smalltext="$right_smalltext${array[3]}"
#       right_icons="$right_icons${array[4]}"
#       right_padding="$(( $right_padding + ${array[5]} ))"
#     done <<< "$($r)"
#   done
#   right_offset="$(( $right_offset + $(xftwidth "$boldfont" "$right_boldtext") ))"
#   right_offset="$(( $right_offset + $(xftwidth "$font" "$right_text") ))"
#   right_offset="$(( $right_offset + $(xftwidth "$smallfont" "$right_smalltext") ))"
#   right_offset="$(( $right_offset + $(xftwidth "$iconfont" "$right_icons") ))"
#   right_offset="$(( $right_offset + $right_padding ))"
#   right_offset="$(( $right_offset + $padding ))"

#   local op="^p(_LEFT)^p($padding)$left_pre$left$left_post \
#   ^p(_CENTER)^p(-$center_offset)$center_pre$center$center_post \
#   ^p(_RIGHT)^p(-$right_offset)$right_pre$right$right_post"
#   echo -e "$op"

# }

while read -r line
do
  linearray=($line)
  config=${linearray[2]}
  w="$(echo ${config} | sed 's/^\([0-9]*\)\/.*/\1/')"
  h="$(echo ${config} | sed 's/^.*x\([0-9]*\)\/.*/\1/')"
  x="$(echo ${config} | sed 's/^.*+\([0-9]*\)+.*/\1/')"
  y="$(echo ${config} | sed 's/^.*+\([0-9]*\)$/\1/')"

  declare -a left center right
  declare -a l_boldtext  c_boldtext  r_boldtext
  declare -a l_text      c_text      r_text
  declare -a l_smalltext c_smalltext r_smalltext
  declare -a l_icons     c_icons     r_icons
  declare -a l_padding   c_padding   r_padding  
  # left_offset center_offset right_offset
  (
    echo $BASHPID >> $f_pid
    echo $BASHPID > $f_c_pid
    trap 'printf " "' SIGUSR1
    while true
    do
      # get and clear change list
      changes="$(cat $f_change)"
      rm -f $f_change
      touch $f_change
      # left
      i=0
      for l in applications spacer terminal spacer desktopSelect spacer windows spacer reload
      do
        if [[ $init = "1" || "$(grep -e "^$l$" -e "^all$" <<< "$changes")" ]]
        then
          while IFS=";" read -a array
          do  
            left[$i]="${array[0]}"
          done <<< "$($l)"
        fi
        i=$(( $i + 1 ))
      done

      # center
      i=0
      update_offset=0
      for c in dateAndTime
      do
        if [[ $init = "1" || "$(grep -e "^$c$" -e "^all$" <<< "$changes")" ]]
        then
          update_offset=1
          while IFS=";" read -a array
          do
            center[$i]="${array[0]}"
            c_boldtext[$i]="${array[1]}"
            c_text[$i]="${array[2]}"
            c_smalltext[$i]="${array[3]}"
            c_icons[$i]="${array[4]}"
            c_padding[$i]="${array[5]}"
          done <<< "$($c)"
        fi
        i=$(( $i + 1 ))
      done
      if [[ $update_offset = "1" ]]
      then
        c_offset=0
        c_offset="$(( $c_offset + $(xftwidth "$boldfont" "$(printf "%s" "${c_boldtext[@]}")") ))"
        c_offset="$(( $c_offset + $(xftwidth "$font" "$(printf "%s" "${c_text[@]}")") ))"
        c_offset="$(( $c_offset + $(xftwidth "$smallfont" "$(printf "%s" "${c_smalltext[@]}")") ))"
        c_offset="$(( $c_offset + $(xftwidth "$iconfont" "$(printf "%s" "${c_icons[@]}")") ))"
        c_offset="$(( $c_offset + $(echo ${c_padding[@]} | sed 's/ /+/g' | bc) ))"      
        c_offset="$(( $c_offset / 2 ))"
      fi

      # right
      i=0
      update_offset=0
      for r in keyboardBlock volumeBlock brightnessBlock batteryBlock networkBlock more
      do
        if [[ $init = "1" || "$(grep -e "^$r$" -e "^all$" <<< "$changes")" ]]
        then
          update_offset=1
          while IFS=";" read -a array
          do    
            right[$i]="${array[0]}"
            r_boldtext[$i]="${array[1]}"
            r_text[$i]="${array[2]}"
            r_smalltext[$i]="${array[3]}"
            r_icons[$i]="${array[4]}"
            r_padding[$i]="${array[5]}"
          done <<< "$($r)"
        fi
        i=$(( $i + 1 ))
      done
      if [[ $update_offset = "1" ]]
      then
        r_offset=0
        r_offset="$(( $r_offset + $(xftwidth "$boldfont" "$(printf "%s" "${r_boldtext[@]}")") ))"
        r_offset="$(( $r_offset + $(xftwidth "$font" "$(printf "%s" "${r_text[@]}")") ))"
        r_offset="$(( $r_offset + $(xftwidth "$smallfont" "$(printf "%s" "${r_smalltext[@]}")") ))"
        r_offset="$(( $r_offset + $(xftwidth "$iconfont" "$(printf "%s" "${r_icons[@]}")") ))"
        r_offset="$(( $r_offset + $(echo ${r_padding[@]} | sed 's/ /+/g' | bc) ))"
        r_offset="$(( $r_offset + $padding ))"
      fi
      
      init=0

      echo -e "^p(_LEFT)^p($padding)$left_pre$(printf "%s" "${left[@]}")$left_post \
        ^p(_CENTER)^p(-$c_offset)$center_pre$(printf "%s" "${center[@]}")$center_post \
        ^p(_RIGHT)^p(-$r_offset)$right_pre$(printf "%s" "${right[@]}")$right_post"
      
      # echo -e "$(createOutput)"
      sleep infinity &
      wait $!
    done
  ) | dzen2 -ta l \
  -x "$x" \
  -y "$y" \
  -w $w \
  -h $panelHeight \
  -fn "$font" \
  -bg "$bgColor" \
  -fg "$fgColor" \
  -e "" &
  # -e "button3=exec:kill -SIGUSR1 $(<$f_c_pid);sigusr1=exec:kill -SIGUSR1 $(<$f_c_pid);onexit=exec:rm -f $f_pid,exit:13" &


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
