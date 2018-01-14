#!/bin/bash
goTo () {
  if [[ $1 = "<" ]]
  then
    coproc( ~/openbox-config/rofi-scripts/rofi-cal-mon.sh $2 $3 )
    exit
  elif [[ $3 = ">" ]]
  then
    coproc( ~/openbox-config/rofi-scripts/rofi-cal-mon.sh $1 $2 )
    exit
  elif [[ $1 =~ ^[0-9]{4}$ ]]
  then
    coproc( ~/openbox-config/rofi-scripts/rofi-cal-year.sh $1 )
    exit
  fi
}

goTo ${@:3}

MONNAME=(invalid Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
for i in "${!MONNAME[@]}"
do
  if [[ "${MONNAME[$i]}" = "$1" ]]
  then
    MON_N=$i
    break
  fi
done
YEAR_N="$2"

MONTH=$(ncal -Sh $MON_N $YEAR_N)

LASTMONTH=$(( $MON_N==1 ? 12 : $MON_N-1 ))
NEXTMONTH=$(( $MON_N==12 ? 1 : $MON_N+1 ))
LASTYEAR=$(( $LASTMONTH==12 ? $YEAR_N-1 : $YEAR_N ))
NEXTYEAR=$(( $NEXTMONTH==1 ? $YEAR_N+1 : $YEAR_N ))

LINE_N=0
while read -r line
do
  for i in 0 3 6 9 12 15 18
  do
    printf "%15s\n" "${line:$i:2}"
  done
  LINE_N=$(($LINE_N+1))
  case "$LINE_N" in
    1)
      printf "%13s\n" "< ${MONNAME[$LASTMONTH]} $LASTYEAR";;
    4)
      printf "%14s\n" "$YEAR_N";;
    7)
      printf "%15s\n" "${MONNAME[$NEXTMONTH]} $NEXTYEAR >";;
    *)
      echo "";;
  esac
done <<< "$(echo "$MONTH" | sed -n '1!p')"
