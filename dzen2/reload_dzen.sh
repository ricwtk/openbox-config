#!/bin/bash
# pkill dzen2 ;
# ~/Applications/openbox-config/dzen2/dzen2_statusbar.sh &
if [ -f /tmp/dzenpid ]
then
  while read -r var
  do
    kill -SIGUSR1 $var
  done < "/tmp/dzenpid"
fi
