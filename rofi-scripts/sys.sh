#!/bin/bash
DIRPATH=~/Applications/openbox-config/rofi-scripts
B_AC="🔌"
B_BAT="🔋"
B_LOGO=""
C_LOGO=""
V_MUTED="🔇"
V_NONE="🔈"
V_SINGLE="🔉"
V_TRIPLE="🔊"
V_LOGO=""
BR_LOW="🔅"
BR_HIGH="☀" #🔆
BR_LOGO="$BR_HIGH"
W_LOGO="📶"
K_LOGO="🔠"
S_LOGO="🖳"
# NONE="○○○○○○○○○○" #\u25cb
NONE="⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀"
# HALF="◐" #\u25D0
HALF="⣦"
# FULL="⬤⬤⬤⬤⬤⬤⬤⬤⬤⬤" #\u2b24
FULL="⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿"
P_LOGO="⏻"
ACTION="☞"
GLOBE_ICON="🌐"
PENCIL_ICON="✏"
TICK="✓"
RT="▶"
CS="\x1d" # column separator
ZWS="$(echo -e '\xe2\x80\x8b')"

DISP=""

# start=`date +%s%N`

removeLeading () {
  sed -e 's/^[[:space:]]*//'
}
removeTrailing () {
  sed -e 's/[[:space:]]*$//'
}

extractData () {
  local DATA="$@"
  DATA=${DATA#*$ZWS}
  DATA=${DATA%%$ZWS*}
  echo $DATA
}

find4In1Between2And3 () {
  local STARTREAD="no"
  while read -r line
  do
    if [[ ! -z $(echo "$line" | grep "$2") ]]
    then
      STARTREAD="yes"
    else
      if [[ "$STARTREAD" = "yes" ]]
      then
        if [[ ! -z $(echo "$line" | grep "$3") ]]
        then
          STARTREAD="no"
          break
        elif [[ ! -z $(echo "$line" | grep "$4") ]]
        then
          echo $line
          break
        fi
      fi
    fi
  done <<< $1
}

setCLogo () {
  local HOUR="$(date +%_I)"
  local MINUTE="$(date +%_M)"
  local CLOCK="$(($HOUR-1+144))"
  if [ $MINUTE -gt 15 ] && [ $MINUTE -lt 45 ]
  then
    CLOCK="$(($CLOCK+12))"
  else
    if [ $MINUTE -gt 45 ]
    then
      CLOCK="$(($CLOCK+1))"
    fi
  fi
  CLOCK="$(printf '%x' $CLOCK)"
  C_LOGO="$(echo -e "\xf0\x9f\x95\x$CLOCK")"
}

setBLogo () {
  if [[ "$(upower -i `upower -e | grep BAT` | grep state | cut -d : -f 2)" = *discharging* ]]
  then
    B_LOGO="$B_BAT"
  else
    B_LOGO="$B_AC"
  fi
}

setVLogo () {
  if [[ "$(isMuted)" = "yes" ]]
  then
    V_LOGO=$V_MUTED
  else
    local CVOL="$(getVolume)"
    if (($CVOL<34))
    then
      V_LOGO=$V_NONE
    elif (($CVOL<67))
    then
      V_LOGO=$V_SINGLE
    else
      V_LOGO=$V_TRIPLE
    fi
  fi
}

getIbusName () {
  local X="$@"
  ibus list-engine | grep " $X " | cut -d "-" -f 2 | removeLeading
}

getIbusEngine () {
  local X="$@"
  ibus list-engine | grep "\- $X$" | cut -d "-" -f 1 | removeLeading
}

isMuted () {
  pacmd list-sinks | cut -d "*" -f 2 | grep -P "^[\t *]muted:" | head -1 | cut -d ":" -f 2 | tr -d "[:space:]"
}
getVolume () {
  echo "$(getVolumeValue)*100/$(getFullVolumeValue)" | bc
}
getVolumeValue () {
  pacmd list-sinks | grep -A999999999 "*" | grep -P "^[\t ]*volume:" | cut -d ":" -f 3 | cut -d "/" -f 1 | tr -d "[:space:]"
}
getFullVolumeValue () {
  pacmd list-sinks | grep -A999999999 "*" | grep -P "^[\t ]*volume steps:" | cut -d ":" -f 2 | tr -d "[:space:]"
}
getCurrentSink () {
  pacmd list-sinks | grep -A999999999 "*" | grep -P "^[\t *]*index:" | cut -d ":" -f 2 | tr -d "[:space:]"
}
toggleMute () {
  if [[ $(isMuted) = "yes" ]]
  then
    pacmd set-sink-mute "$(getCurrentSink)" no
  else
    pacmd set-sink-mute "$(getCurrentSink)" yes
  fi
}
stepUpVolume () {
  local fullVolumeValue=$(getFullVolumeValue)
  local newVol="$(echo $(getVolumeValue)+${fullVolumeValue}*5/100 | bc)"
  if [[ $newVol -gt $fullVolumeValue ]]
  then
    newVol=$fullVolumeValue
  fi
  pacmd set-sink-volume $(getCurrentSink) "$newVol"
}
stepDownVolume () {
  local fullVolumeValue=$(getFullVolumeValue)
  local newVol="$(echo $(getVolumeValue)-${fullVolumeValue}*5/100 | bc)"
  if [[ $newVol -lt "0" ]]
  then
    newVol=0
  fi
  pacmd set-sink-volume $(getCurrentSink) "$newVol"
}

getActiveMons () {
  xrandr --listactivemonitors | grep -v "Monitors" | sed 's/.* \(.*\)$/\1/'
}
getBrightness () {
  local a="$(xrandr --verbose | grep -A999 "^$1" | grep -m1 -P -i "^[\t ]*Brightness:" | cut -d ":" -f 2 | tr -d "[:space:]")"
  echo "$(echo "scale=0; $a*100/1" | bc)%"
}

loadHome () {
  local DISP=""
  # date and Time
  setCLogo
  DISP="$DISP\n$C_LOGO$CS$(date +"$ZWS%a$ZWS %d %b %Y$CS%H:%M")"

  # volume
  setVLogo
  DISP="$DISP\n$V_LOGO${CS}${ZWS}Volume$ZWS$CS$(getVolume)%"

  # brightness
  DISP="$DISP\n$BR_LOGO${CS}${ZWS}Brightness$ZWS"

  # wireless
  while IFS= read -r line
  do
    PARAM="$(echo $line | cut -d ":" -f 2 | removeLeading)"
    case "$(echo $line | cut -d ":" -f 1)" in
      NAME)
        NETNAME=$PARAM
        ;;
      TYPE)
        if [[ $PARAM = *wireless* ]]
        then
          break
        else
          NETNAME=""
        fi
        ;;
    esac
  done <<< "$(nmcli -m multiline con show --active)"
  DISP="$DISP\n$W_LOGO${CS}${ZWS}Wireless$ZWS$CS$NETNAME"

  # keyboard
  KEYBOARD="$(getIbusName `ibus engine`)"
  if [[ -z $KEYBOARD ]]
  then
    KEYBOARD="Ibus is disabled"
  fi
  DISP="$DISP\n$K_LOGO${CS}${ZWS}Keyboard$ZWS${CS}$KEYBOARD"

  # battery
  setBLogo
  local BAT_PERCENTAGE="$(upower -i `upower -e | grep BAT` | grep percentage | cut -d : -f 2 | tr -d [:space:])"
  DISP="$DISP\n${B_LOGO}${CS}${ZWS}Battery$ZWS${CS}${BAT_PERCENTAGE}"

  # cpu
  DISP="$DISP\n${S_LOGO}${CS}${ZWS}Stats$ZWS"

  # power
  DISP="$DISP\n$P_LOGO$CS${ZWS}Power$ZWS"

  # for option in ${!option@}; do
  #   DISP="$DISP\n${option[name]}"
  # done
  echo $DISP
}

loadVolume () {
  setVLogo
  local DISP="$V_LOGO$CS.."
  if [[ "$(isMuted)" = "yes" ]]
  then
    DISP="$DISP\n$V_LOGO $ACTION${CS}${ZWS}Muted$ZWS"
  else
    DISP="$DISP\n$V_LOGO $ACTION${CS}${ZWS}$(getVolume)%$ZWS"
    DISP="$DISP\n$V_LOGO $ACTION${CS}${ZWS}+5%$ZWS"
    DISP="$DISP\n$V_LOGO $ACTION${CS}${ZWS}-5%$ZWS"
  fi
  # sink
  # local ACTIVESINK="$(stdbuf -o0 pacmd list-sinks | grep -A999999999 "*")"
  # local ACTIVESINKPORT="$(echo "$ACTIVESINK" | grep -m1 -P "^[\t ]*active port:" | sed 's/.*<\(.*\)>.*/\1/')"
  # ACTIVESINKPORT=$(find4In1Between2And3 "$ACTIVESINK" "^[\t ]*ports:" "^[\t ]*active port:" "^[\t ]*$ACTIVESINKPORT" | sed 's/.*:\(.*\)(.*/\1/' | removeLeading | removeTrailing)
  # DISP="$DISP\n$V_LOGO $ACTION$CS${ZWS}Sink$ZWS$CS$ACTIVESINKPORT"
  #
  # local ACTIVESOURCE="$(stdbuf -o0 pacmd list-sources | grep -A999999999 "*")"
  # local ACTIVESOURCEPORT="$(echo "$ACTIVESOURCE"| grep -m1 -P "^[\t ]*active port:" | sed 's/.*<\(.*\)>.*/\1/')"
  # ACTIVESOURCEPORT=$(find4In1Between2And3 "$ACTIVESOURCE" "^[\t ]*ports:" "^[\t ]*active port:" "^[\t ]*$ACTIVESOURCEPORT" | sed 's/.*:\(.*\)(.*/\1/' | removeLeading | removeTrailing)
  # DISP="$DISP\n$V_LOGO $ACTION$CS${ZWS}Source$ZWS$CS$ACTIVESOURCEPORT"

  #pacmd set-sink-port alsa_output.pci-0000_00_1b.0.analog-stereo analog-output-headphones
  DISP="$DISP\n$V_LOGO $ACTION${CS}${ZWS}Preferences$ZWS"
  echo $DISP
}

loadBrightness () {
  local DISP="$BR_LOGO$CS${ZWS}..$ZWS"
  DISP="$DISP\n$BR_LOGO $ACTION$CS${ZWS}Light off$ZWS"
  DISP="$DISP\n$BR_LOGO $ACTION$CS${ZWS}Dim all$ZWS"
  DISP="$DISP\n$BR_LOGO $ACTION$CS${ZWS}Brighten all$ZWS"
  local ACTIVEMONS="$(getActiveMons)"
  while read -r line
  do
    DISP="$DISP\n$BR_LOGO $ACTION$CS$ZWS$line$ZWS$CS$(getBrightness "$line")"
  done <<< "$ACTIVEMONS"
  DISP="$DISP\n$BR_LOGO $ACTION$CS${ZWS}Monitors configurations$ZWS"
  echo $DISP
}
loadSingleMon () {
  local DISP="$BR_LOGO$CS${ZWS}Brightness$ZWS$CS$RT$CS$(getBrightness "$1")"
  for i in 5 10 25 50 75 100
  do
    DISP="$DISP\n$BR_LOGO $ACTION$ACTION$CS$ZWS$1${ZWS}$CS$i%"
  done
  echo $DISP
}

loadWireless () {
  local DISP="$DISP\n$W_LOGO$CS$ZWS..$ZWS"
  DISP="$DISP\n${W_LOGO} ${ACTION}$CS$ZWS$(nmcli radio wifi)${ZWS}"
  DISP="$DISP\n${W_LOGO} ${ACTION}${CS}${ZWS}Rescan${ZWS}"
  DISP="$DISP\n${W_LOGO} ${ACTION}${CS}${ZWS}Extended settings${ZWS}"
  while IFS= read -r line ; do
    if [[ $line = "*"* ]]; then
      CONNECTED=$(echo $line | cut -d ':' -f 2 | tr -d [:space:])
      if [[ $CONNECTED = "" ]]; then
        CONNECTED=" "
      else
        CONNECTED="$TICK"
      fi
    fi
    if [[ $line = "SSID"* ]]; then
      SSID="$(echo $line | cut -d ':' -f 2 | tr -d [:space:])"
    fi
    if [[ $line = "BARS"* ]]; then
      BARS="$(echo $line | cut -d ':' -f 2 | tr -d [:space:])"
    fi
    if [[ $line = "SECURITY"* ]]; then
      DISP="$DISP\n$W_LOGO $GLOBE_ICON$CS${ZWS}$SSID${ZWS}$CS$BARS$CS$CONNECTED"
    fi
  done <<< "$(nmcli -m multiline device wifi list)"
  echo $DISP
}

loadKeyboard () {
  local DISP="$K_LOGO$CS$ZWS..$ZWS"
  if [[ -z "$(ibus engine)" ]]
  then
    DISP="$DISP\n$K_LOGO $ACTION$CS${ZWS}Start Ibus$ZWS"
  else
    local ENGINES="$(ibus read-config | grep "engines-order")"
    ENGINES=${ENGINES#*[}
    ENGINES=${ENGINES%%]}
    ENGINES=${ENGINES//\'}
    while IFS="," read -a ARRAY
    do
      for i in "${ARRAY[@]}"
      do
        DISP="$DISP\n$K_LOGO $PENCIL_ICON$CS$ZWS$(getIbusName $i)$ZWS"
      done
    done <<< "$ENGINES"
    DISP="$DISP\n$K_LOGO $ACTION${CS}${ZWS}Preferences$ZWS"
    DISP="$DISP\n$K_LOGO $ACTION${CS}${ZWS}Restart Ibus$ZWS"
    DISP="$DISP\n$K_LOGO $ACTION${CS}${ZWS}Exit Ibus$ZWS"
  fi
  echo $DISP
}

loadBattery () {
  setBLogo
  local DISP="$B_LOGO$CS.."
  while read -r line
  do
    local DETAILS="$(upower -i $line)"
    if [[ ! -z $(printf "$DETAILS" | grep "^ *native-path:") ]]
    then
      if [[ ! -z $(printf "$DETAILS" | grep "^ *line-power$") ]]
      then
        if [[ "$(printf "$DETAILS" | grep "^ *online" | cut -d ":" -f 2 | tr -d [:space:])" = "yes" ]]
        then
          local SHOW="AC connected"
        else
          local SHOW="AC not connected"
        fi
      elif [[ ! -z $(printf "$DETAILS" | grep "^ *battery$") ]] || [[ ! -z $(upower -i $line | grep "^ *mouse$") ]]
      then
        local VENDOR="$(printf "$DETAILS" | grep "^ *vendor:" | cut -d ":" -f 2 | removeLeading)"
        local MODEL="$(printf "$DETAILS" | grep "^ *model:" | cut -d ":" -f 2 | removeLeading)"
        local PERCENTAGE="$(printf "$DETAILS" | grep "^ *percentage:" | cut -d ":" -f 2 | removeLeading)%"
        local SHOW="$(echo $VENDOR $MODEL$CS$PERCENTAGE | removeLeading)"
      else
        local SHOW=""
      fi
      DISP="$DISP\n$B_LOGO $ACTION$CS$SHOW"
    fi
  done <<< "$(upower -e)"
  echo $DISP
}

getProgress () {
  local NFULL="$(echo "$1/10"|bc)"
  case "$(echo "$1%10/1" | bc)" in
    [0-2])
      local MID="${NONE:0:1}";;
    [3-7])
      local MID="$HALF";;
    [8-9])
      local MID="${FULL:0:1}";;
  esac
  local NNONE="$(echo "10-$NFULL-1"|bc)"
  echo "${FULL:0:$NFULL}$MID${NONE:0:$NNONE}"
}
getGB () {
  echo "scale=2; $1/1024/1024" | bc
}
loadStats () {
  local DISP="$S_LOGO$CS$ZWS..$ZWS"
  local MEMSWAP="$(free --kilo)"
  local USEDMEM="$(echo "$MEMSWAP" | awk '/^Mem:/ {printf $3}')"
  local ALLMEM="$(echo "$MEMSWAP" | awk '/^Mem:/ {printf $2}')"
  local MEMPERC="$(echo "$USEDMEM*100/$ALLMEM" | bc)"
  DISP="$DISP\n$S_LOGO $ACTION$CS${ZWS}Memory$ZWS$CS$(getProgress $MEMPERC)$CS$MEMPERC$CS%$CS$(getGB $USEDMEM)${CS}of $(getGB $ALLMEM)${CS}GB"
  local USEDSWAP="$(echo "$MEMSWAP" | awk '/^Swap:/ {printf $3}')"
  local ALLSWAP="$(echo "$MEMSWAP" | awk '/^Swap:/ {printf $2}')"
  local SWAPPERC="$(echo "$USEDSWAP*100/$ALLSWAP" | bc)"
  DISP="$DISP\n$S_LOGO $ACTION$CS${ZWS}Swap$ZWS$CS$(getProgress $SWAPPERC)$CS$SWAPPERC$CS%$CS$(getGB $USEDSWAP)${CS}of $(getGB $ALLSWAP)${CS}GB"
  while read -r line
  do
    local PERC="$(echo $line | awk '{for (i=2;i<=NF;i++){sum+=$i}}END{printf "%.2f",100-$5*100/sum}')"
    local NAME="$(echo $line | cut -d " " -f 1 | tr [:lower:] [:upper:])"
    DISP="$DISP\n$S_LOGO $ACTION$CS$ZWS$NAME$ZWS$CS$(getProgress $PERC)$CS$PERC$CS%"
  done <<< "$(cat /proc/stat | grep -i "^cpu")"
  local DISP="$DISP\n$S_LOGO $ACTION${CS}${ZWS}Advance$ZWS"
  echo $DISP
}

loadPower () {
  local DISP="$P_LOGO$CS.."
  DISP="$DISP\n$P_LOGO $ACTION${CS}${ZWS}Lock screen$ZWS"
  DISP="$DISP\n$P_LOGO $ACTION${CS}${ZWS}Log out$ZWS"
  DISP="$DISP\n$P_LOGO $ACTION${CS}${ZWS}Suspend$ZWS"
  DISP="$DISP\n$P_LOGO $ACTION${CS}${ZWS}Hibernate$ZWS"
  DISP="$DISP\n$P_LOGO $ACTION${CS}${ZWS}Shut down$ZWS"
  DISP="$DISP\n$P_LOGO $ACTION${CS}${ZWS}Restart$ZWS"
  echo $DISP
}

if [ $# -eq 0 ]
then
  DISP="$DISP\n$(loadHome)"
else
  if [ $# -eq 1 ]
  then
    setCLogo
    setBLogo
    case $1 in
      $B_LOGO*$ACTION*)
        DISP="$DISP\n$(loadBattery)"
        ;;
      $C_LOGO*)
        coproc( $DIRPATH/rofi-cal-mon.sh $(date +%b\ %Y) )
        exit
        ;;
      $V_MUTED*$ACTION* | $V_NONE*$ACTION* | $V_SINGLE*$ACTION* | $V_TRIPLE*$ACTION*)
        DATA="$(extractData $1)"
        case $DATA in
          +5%)
            stepUpVolume
            DISP="$DISP\n$(loadVolume)"
            ;;
          -5%)
            stepDownVolume
            DISP="$DISP\n$(loadVolume)"
            ;;
          Preferences)
            coproc( pavucontrol > /dev/null 2>&1 )
            ;;
          *)
            toggleMute
            DISP="$DISP\n$(loadVolume)"
            ;;
        esac
        ;;
      $BR_LOGO*$ACTION$ACTION*)
        MON="$(extractData $1)"
        PERC="$(echo "$1" | sed 's/.* \(.*\)\%$/\1/')"
        xrandr --output $MON --brightness "$(echo "scale=2; $PERC/100" | bc)"
        DISP="$DISP\n$(loadSingleMon "$MON")"
        ;;
      $BR_LOGO*$ACTION*)
        DATA="$(extractData $1)"
        case $DATA in
          "Light off")
            while read -r line
            do
              xrandr --output $line --brightness 0.05
            done <<< "$(getActiveMons)"
            DISP="$DISP\n$(loadBrightness)"
            ;;
          "Dim all")
            while read -r line
            do
              xrandr --output $line --brightness 0.5
            done <<< "$(getActiveMons)"
            DISP="$DISP\n$(loadBrightness)"
            ;;
          "Brighten all")
            while read -r line
            do
              xrandr --output $line --brightness 1.0
            done <<< "$(getActiveMons)"
            DISP="$DISP\n$(loadBrightness)"
            ;;
          "Monitors configurations")
            coproc( arandr > /dev/null 2>&1 )
            ;;
          *)
            DISP="$DISP\n$(loadSingleMon "$DATA")"
          ;;
        esac
        ;;
      $W_LOGO*$ACTION*)
        DATA="$(extractData $1)"
        case $DATA in
          Rescan)
            nmcli device wifi rescan
            DISP="$DISP\n$W_LOGO${CS}Wireless${CS}>${CS}.."
            DISP="$DISP\n$W_LOGO${CS}Rescanning.."
            ;;
          enabled)
            nmcli radio wifi off
            DISP="$DISP\n$(loadWireless)"
            ;;
          disabled)
            nmcli radio wifi on
            sleep 1
            DISP="$DISP\n$(loadWireless)"
            ;;
          "Extended settings")
            coproc( x-terminal-emulator --show -e nmtui > /dev/null 2>&1 ) # this option is meant for Guake
            ;;
        esac
        ;;
      $W_LOGO*$GLOBE_ICON*)
        DATA="$(extractData $1)"
        DISP="$DISP\n$W_LOGO${CS}Wireless${CS}>${CS}.."
        DISP="$DISP\n$W_LOGO${CS}Connecting to $DATA"
        if [[ -z "$(nmcli -m multiline con | grep -E "NAME: +$DATA$")" ]]
        then
          coproc( nmcli dev wifi connect "$DATA" > /dev/null 2>&1 )
        else
          coproc( nmcli con up "$DATA" > /dev/null 2>&1 )
        fi
        ;;
      $K_LOGO*$ACTION*)
        DATA="$(extractData $1)"
        case "$DATA" in
          Preferences)
            coproc( ibus-setup > /dev/null 2>&1 )
            ;;
          "Start Ibus")
            coproc( ibus-daemon > /dev/null 2>&1 )
            sleep .5
            DISP="$DISP\n$(loadHome)"
            ;;
          "Restart Ibus")
            ibus restart
            sleep .5
            DISP="$DISP\n$(loadHome)"
            ;;
          "Exit Ibus")
            ibus exit
            DISP="$DISP\n$(loadHome)"
            ;;
        esac
        ;;
      $K_LOGO*$PENCIL_ICON*)
        DATA="$(extractData $1)"
        ibus engine `getIbusEngine $DATA`
        DISP="$DISP\n$(loadHome)"
        ;;
      $S_LOGO*$ACTION*)
        DATA="$(extractData $1)"
        case $DATA in
          Advance)
            coproc( gnome-system-monitor > /dev/null 2>&1 )
            ;;
          *)
            DISP="$DISP\n$(loadStats)"
            ;;
        esac
        ;;
      $P_LOGO*$ACTION*)
        DATA="$(extractData $1)"
        case "$DATA" in
          "Lock screen")
            coproc( xscreensaver-command -lock >/dev/null 2>&1 )
            ;;
          "Log out")
            coproc( pkill openbox > /dev/null 2>&1 )
            ;;
          "Suspend")
            coproc( systemctl suspend > /dev/null 2>&1 )
            ;;
          "Hibernate")
            coproc( systemctl hibernate > /dev/null 2>&1 )
            ;;
          "Shut down")
            coproc( systemctl poweroff > /dev/null 2>&1 )
            ;;
          "Restart")
            coproc( systemctl reboot > /dev/null 2>&1 )
            ;;
        esac
        ;;
      *)
        case "$(extractData $1)" in
          ..)
            DISP="$DISP\n$(loadHome)"
            ;;
          Volume)
            DISP="$DISP\n$(loadVolume)"
            ;;
          Brightness)
            DISP="$DISP\n$(loadBrightness)"
            ;;
          Wireless)
            DISP="$DISP\n$(loadWireless)"
            ;;
          Keyboard)
            DISP="$DISP\n$(loadKeyboard)"
            ;;
          Battery)
            DISP="$DISP\n$(loadBattery)"
            ;;
          Stats)
            DISP="$DISP\n$(loadStats)"
            ;;
          Power)
            DISP="$DISP\n$(loadPower)"
            ;;
          *)
            DISP="$DISP\n$(loadHome)"
            ;;
        esac
      ;;
    esac
  fi
fi
echo -e "$DISP" | column -t -s$'\x1d'

# WIFI_STATUS="$(nmcli radio wifi)"
# WIFILIST="$(nmcli device wifi list)"
# echo "${WIFI_STATUS}\n${WIFILIST}"

# end=`date +%s%N`
# echo $((end-start))
