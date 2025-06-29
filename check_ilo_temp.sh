#!/usr/bin/env bash

ILO=10.0.0.79
USER=Admin
PASS='Clement27930'
SENSORS='01-Inlet Ambient|02-CPU 1|03-CPU 2|12-HD Max|36-Sys Exhaust|37-Sys Exhaust'

while true; do
  clear
  ipmitool -I lanplus -H "$ILO" -U "$USER" -P "$PASS" sdr type temperature 2>/dev/null \
    | grep -E "$SENSORS" \
    | awk -F'|' '
      {
        name    = $1
        reading = $5
        # nettoyage
        gsub(/ degrees C$/,    "", reading)
        gsub(/^[ \t]+|[ \t]+$/, "", name)
        gsub(/^[ \t]+|[ \t]+$/, "", reading)

        # seuil critique pour 12-HD Max
        if (name == "12-HD Max") {
          crit = 60
          if (reading+0 >= 58) {
            # rouge + emojis
            printf "%-16s → \033[31m🔥 %s °C (crit : %d °C) 🔥\033[0m\n", name, reading, crit
          } else {
            printf "%-16s → %s °C (crit : %d °C)\n", name, reading, crit
          }
        }
        else {
          # autres capteurs
          printf "%-16s → %s °C\n", name, reading
        }
      }'
  sleep 5
done
