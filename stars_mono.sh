#!/bin/bash

# Set star density (higher = fewer stars)
density=10
# Set twinkle speed (lower = faster)
speed=0.05

# Initialize
clear
tput civis  # Hide cursor

# Main loop
while true; do
  # Get terminal dimensions each iteration (resize-safe)
  cols=$(tput cols)
  lines=$(tput lines)
  
  # Print new stars randomly
  for ((i=0; i<lines; i++)); do
    if (( RANDOM % density == 0 )); then
      x=$((RANDOM % cols))
      y=$((RANDOM % lines))
      # Brightness variability (bold/dim) for twinkling effect
      style=$(( RANDOM % 2 + 1 ))
      echo -ne "\e[${y};${x}H\e[${style}m*\e[0m"
    fi
  done

  sleep "$speed"

  # Fade effect: randomly clear some stars
  for ((i=0; i<lines/2; i++)); do
    x=$((RANDOM % cols))
    y=$((RANDOM % lines))
    echo -ne "\e[${y};${x}H "
  done
done
