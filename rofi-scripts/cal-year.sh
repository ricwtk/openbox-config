#!/bin/bash
MONNAME=(invalid Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
goTo () {
  case "$@" in
    "<"*)
      coproc( ~/openbox-config/rofi-scripts/rofi-cal-year.sh $2 )
      exit
      ;;
    *">")
      coproc( ~/openbox-config/rofi-scripts/rofi-cal-year.sh $1 )
      exit
      ;;
    [a-Z]*)
      coproc( ~/openbox-config/rofi-scripts/rofi-cal-mon.sh $1 $2 )
      exit
      ;;
  esac
}
goTo ${@:2}
for i in 1 2 3
do
  for j in 0 3 6 9
  do
    printf "%10s %s\n" ${MONNAME[$(($i+$j))]} $1
  done
  if [[ $i = 1 ]]
  then
    printf "%8s\n" "< $(($1-1))"
  elif [[ $i = 3 ]]
  then
    printf "%23s\n" "$(($1+1)) >"
  else
    echo ""
  fi
done
