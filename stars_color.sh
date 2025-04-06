#!/bin/bash

# Settings
density=8           # Higher = fewer stars (try 5-15)
speed=0.05          # Lower = faster twinkling
colors=(31 33 32 36 34 35 37)  # ANSI color codes: RED, YELLOW, GREEN, CYAN, BLUE, MAGENTA, WHITE

# Hide cursor and clear screen                                                     
clear                                                                              
tput civis                                                                        
trap 'tput cnorm; clear' EXIT  # Restore cursor on exit

# Main loop                                                                       
while true; do                                                                    
  # Get terminal size (works on resize too)                                       
  cols=$(tput cols)                                                               
  lines=$(tput lines)                                                             
  
  # Draw new stars                                                                
  for ((i=0; i<lines; i++)); do                                                  
    if (( RANDOM % density == 0 )); then                                         
      x=$(( RANDOM % cols ))                                                     
      y=$(( RANDOM % lines ))                                                    
      color="${colors[$(( RANDOM % ${#colors[@]} ))]}"   # Random color          
      brightness=$(( RANDOM % 2 + 1 ))              # 1=dim, 2=bright            
      echo -ne "\e[${y};${x}H\e[${brightness};${color}m*\e[0m"                   
    fi                                                                           
  done                                                                           

  sleep "$speed"                                                                 

  # Fade effect: Clear ~50% of stars                                             
  for ((i=0; i<lines; i+=2)); do                                                
    x=$(( RANDOM % cols ))                                                       
    y=$(( RANDOM % lines ))                                                      
    echo -ne "\e[${y};${x}H "                                                    
  done                                                                           
done
