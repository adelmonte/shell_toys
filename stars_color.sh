#!/bin/bash
# Settings
density=8            # Higher = fewer stars
speed=0.1           # Animation speed
max_stars=200       # Maximum stars on screen
twinkle_chance=20   # % chance a star will change brightness
respawn_chance=3    # % chance a star will respawn elsewhere
monotone=false      # Toggle for monotone mode
lightspeed=false    # Toggle for lightspeed mode
constellation=false # Toggle for constellation mode
paused=false        # Toggle for pause
gravity=false       # Toggle for gravity well
reverse=false       # Toggle for reverse lightspeed
show_help=false     # Toggle for help display
auto_shooting=false # Toggle for automatic shooting stars
planets=false       # Toggle for planets
show_status=false   # Toggle for status bar (hidden by default)

# Hide cursor and clear screen
clear
tput civis
# Disable echo for keypresses
stty -echo
trap 'tput cnorm; stty echo; clear' EXIT

# Star array: x,y,brightness,color,lifetime,trail_length,vx,vy
declare -a stars
declare -a shooting_stars
declare -a constellation_groups
declare -a planet_list

# Initialize random stars
init_stars() {
  stars=()
  cols=$(tput cols)
  lines=$(tput lines)
  
  # Density directly controls number of stars
  case $density in
    3) star_count=180 ;;
    4) star_count=150 ;;
    5) star_count=120 ;;
    6) star_count=100 ;;
    7) star_count=80 ;;
    8) star_count=60 ;;
    9) star_count=50 ;;
    10) star_count=40 ;;
    11) star_count=35 ;;
    12) star_count=30 ;;
    13) star_count=25 ;;
    14) star_count=20 ;;
    15) star_count=18 ;;
    16) star_count=15 ;;
    17) star_count=13 ;;
    18) star_count=11 ;;
    19) star_count=9 ;;
    20) star_count=7 ;;
    *) star_count=50 ;;
  esac
  
  for ((i=0; i<star_count; i++)); do
    x=$(( RANDOM % cols ))
    y=$(( RANDOM % (lines - 1) ))  # Leave room for status bar
    brightness=$(( RANDOM % 3 ))  # 0=dim, 1=normal, 2=bright
    color=$(( RANDOM % 7 + 31 ))  # Random color 31-37
    lifetime=$(( RANDOM % 50 + 20 ))  # How many frames before respawn
    trail_length=0  # For lightspeed effect
    vx=0  # velocity x
    vy=0  # velocity y
    stars+=("$x,$y,$brightness,$color,$lifetime,$trail_length,$vx,$vy")
  done
}

# Initialize planets
init_planets() {
  planet_list=()
  if [[ "$planets" != "true" ]]; then
    return
  fi
  
  local planet_emojis=("☿" "♀" "♁" "♂" "♃" "♄" "⛢" "♆" "♇" "🪐" "🌍" "☀️" "🌛")
  local num_planets=$(( RANDOM % 3 + 2 ))  # 2-4 planets
  
  for ((i=0; i<num_planets; i++)); do
    local px=$(( RANDOM % (cols - 2) + 1 ))
    local py=$(( RANDOM % (lines - 2) + 1 ))
    local emoji=${planet_emojis[$(( RANDOM % ${#planet_emojis[@]} ))]}
    planet_list+=("$px,$py,$emoji")
  done
}

# Draw planets
draw_planets() {
  [[ "$planets" != "true" ]] && return
  
  for planet in "${planet_list[@]}"; do
    IFS=',' read -r x y emoji <<< "$planet"
    [[ $y -lt $((lines-1)) ]] && echo -ne "\e[${y};${x}H${emoji}"
  done
}

# Generate constellations with proper connections
generate_constellations() {
  constellation_groups=()
  local num_constellations=$(( RANDOM % 2 + 1 ))  # 1-2 constellations at once
  
  for ((c=0; c<num_constellations; c++)); do
    local base_x=$(( RANDOM % (cols - 20) + 10 ))
    local base_y=$(( RANDOM % (lines - 12) + 6 ))
    local pattern_type=$(( RANDOM % 8 ))
    local rotation=$(( RANDOM % 4 ))  # 0, 90, 180, 270 degrees
    
    # Store points and connections separately
    local points=()
    local connections=()
    
    case $pattern_type in
      0) # Orion-like
        points=(
          "$((base_x-4)),$((base_y-6))"   # 0
          "$((base_x+4)),$((base_y-6))"   # 1
          "$((base_x-6)),$((base_y-2))"   # 2
          "$((base_x-2)),$((base_y-1))"   # 3
          "$((base_x+2)),$((base_y-1))"   # 4
          "$((base_x+6)),$((base_y-2))"   # 5
          "$((base_x-3)),$((base_y+2))"   # 6
          "$((base_x)),$((base_y+3))"     # 7
          "$((base_x+3)),$((base_y+2))"   # 8
        )
        connections="0-2,1-5,2-3,3-4,4-5,3-6,4-8,6-7,7-8"
        ;;
      1) # Big Dipper-like
        points=(
          "$((base_x-8)),$((base_y-4))"   # 0
          "$((base_x-4)),$((base_y-5))"   # 1
          "$((base_x)),$((base_y-4))"     # 2
          "$((base_x+3)),$((base_y-2))"   # 3
          "$((base_x+2)),$((base_y+1))"   # 4
          "$((base_x-1)),$((base_y+2))"   # 5
          "$((base_x-4)),$((base_y+1))"   # 6
        )
        connections="0-1,1-2,2-3,3-4,4-5,5-6,6-0"
        ;;
      2) # W-shape (Cassiopeia-like)
        points=(
          "$((base_x-8)),$((base_y-2))"   # 0
          "$((base_x-4)),$((base_y+2))"   # 1
          "$((base_x)),$((base_y-1))"     # 2
          "$((base_x+4)),$((base_y+2))"   # 3
          "$((base_x+8)),$((base_y-2))"   # 4
        )
        connections="0-1,1-2,2-3,3-4"
        ;;
      3) # Cross (Southern Cross-like)
        points=(
          "$((base_x)),$((base_y-6))"     # 0
          "$((base_x)),$((base_y-2))"     # 1
          "$((base_x)),$((base_y+2))"     # 2
          "$((base_x)),$((base_y+6))"     # 3
          "$((base_x-4)),$((base_y))"     # 4
          "$((base_x+4)),$((base_y))"     # 5
        )
        connections="0-1,1-2,2-3,4-2,2-5"
        ;;
      4) # Triangle
        points=(
          "$((base_x)),$((base_y-5))"     # 0
          "$((base_x-5)),$((base_y+3))"   # 1
          "$((base_x+5)),$((base_y+3))"   # 2
        )
        connections="0-1,1-2,2-0"
        ;;
      5) # Zigzag
        points=(
          "$((base_x-6)),$((base_y-4))"   # 0
          "$((base_x-3)),$((base_y-2))"   # 1
          "$((base_x)),$((base_y-4))"     # 2
          "$((base_x+3)),$((base_y-2))"   # 3
          "$((base_x+6)),$((base_y-4))"   # 4
          "$((base_x+3)),$((base_y))"     # 5
          "$((base_x)),$((base_y+2))"     # 6
          "$((base_x-3)),$((base_y+4))"   # 7
        )
        connections="0-1,1-2,2-3,3-4,4-5,5-6,6-7"
        ;;
      6) # Square
        points=(
          "$((base_x-4)),$((base_y-4))"   # 0
          "$((base_x+4)),$((base_y-4))"   # 1
          "$((base_x+4)),$((base_y+4))"   # 2
          "$((base_x-4)),$((base_y+4))"   # 3
        )
        connections="0-1,1-2,2-3,3-0"
        ;;
      7) # Arrow
        points=(
          "$((base_x)),$((base_y-6))"     # 0
          "$((base_x)),$((base_y-2))"     # 1
          "$((base_x)),$((base_y+2))"     # 2
          "$((base_x)),$((base_y+6))"     # 3
          "$((base_x-3)),$((base_y-3))"   # 4
          "$((base_x+3)),$((base_y-3))"   # 5
        )
        connections="0-1,1-2,2-3,4-1,1-5"
        ;;
    esac
    
    # Apply rotation if needed
    local rotated_points=()
    for point in "${points[@]}"; do
      IFS=',' read -r px py <<< "$point"
      local rx=$px
      local ry=$py
      
      # Rotate around base point
      case $rotation in
        1) # 90 degrees
          rx=$((base_x - (py - base_y)))
          ry=$((base_y + (px - base_x)))
          ;;
        2) # 180 degrees
          rx=$((base_x - (px - base_x)))
          ry=$((base_y - (py - base_y)))
          ;;
        3) # 270 degrees
          rx=$((base_x + (py - base_y)))
          ry=$((base_y - (px - base_x)))
          ;;
      esac
      rotated_points+=("$rx,$ry")
    done
    
    # Store constellation with its connections
    constellation_groups+=("${rotated_points[*]}|$connections")
  done
}

# Draw status bar
draw_status() {
  [[ "$show_status" != "true" ]] && return
  
  local status_line=$((lines - 1))
  echo -ne "\e[${status_line};0H\e[K\e[7m"  # Clear line and inverse video
  
  # Build status string
  local status="[h]elp [B]ar"
  [[ "$paused" == "true" ]] && status="$status | PAUSED"
  [[ "$lightspeed" == "true" ]] && status="$status | Lightspeed"
  [[ "$reverse" == "true" ]] && status="$status | Reverse"
  [[ "$gravity" == "true" ]] && status="$status | Gravity"
  [[ "$monotone" == "true" ]] && status="$status | Mono"
  [[ "$constellation" == "true" ]] && status="$status | Constellation"
  [[ "$auto_shooting" == "true" ]] && status="$status | Shooting★"
  [[ "$planets" == "true" ]] && status="$status | Planets"
  status="$status | Density:$density | Speed:$speed"
  
  # Center the status
  local padding=$(( (cols - ${#status}) / 2 ))
  printf "%*s%s" $padding "" "$status"
  echo -ne "\e[0m"  # Reset
}

# Draw help overlay
draw_help() {
  local help_y=5
  local help_x=$(( (cols - 40) / 2 ))
  [[ $help_x -lt 0 ]] && help_x=0
  
  echo -ne "\e[${help_y};${help_x}H\e[1;37m╔══════════════════════════════════════╗\e[0m"
  echo -ne "\e[$((help_y+1));${help_x}H\e[1;37m║         STARFIELD CONTROLS           ║\e[0m"
  echo -ne "\e[$((help_y+2));${help_x}H\e[1;37m╠══════════════════════════════════════╣\e[0m"
  echo -ne "\e[$((help_y+3));${help_x}H\e[1;37m║ h/?    - Toggle this help            ║\e[0m"
  echo -ne "\e[$((help_y+4));${help_x}H\e[1;37m║ SPACE  - Pause/Resume                ║\e[0m"
  echo -ne "\e[$((help_y+5));${help_x}H\e[1;37m║ t      - Lightspeed mode             ║\e[0m"
  echo -ne "\e[$((help_y+6));${help_x}H\e[1;37m║ r      - Reverse lightspeed          ║\e[0m"
  echo -ne "\e[$((help_y+7));${help_x}H\e[1;37m║ g      - Gravity well                ║\e[0m"
  echo -ne "\e[$((help_y+8));${help_x}H\e[1;37m║ m      - Monotone mode               ║\e[0m"
  echo -ne "\e[$((help_y+9));${help_x}H\e[1;37m║ c      - Constellation mode          ║\e[0m"
  echo -ne "\e[$((help_y+10));${help_x}H\e[1;37m║ p      - Planet mode                 ║\e[0m"
  echo -ne "\e[$((help_y+11));${help_x}H\e[1;37m║ S      - Toggle auto shooting stars  ║\e[0m"
  echo -ne "\e[$((help_y+12));${help_x}H\e[1;37m║ s      - Spawn shooting star         ║\e[0m"
  echo -ne "\e[$((help_y+13));${help_x}H\e[1;37m║ +/-    - Increase/Decrease density   ║\e[0m"
  echo -ne "\e[$((help_y+14));${help_x}H\e[1;37m║ ,/.    - Slower/Faster               ║\e[0m"
  echo -ne "\e[$((help_y+15));${help_x}H\e[1;37m║ B      - Toggle status bar           ║\e[0m"
  echo -ne "\e[$((help_y+16));${help_x}H\e[1;37m║ q/ESC  - Quit                        ║\e[0m"
  echo -ne "\e[$((help_y+17));${help_x}H\e[1;37m╚══════════════════════════════════════╝\e[0m"
}

# Create shooting star
create_shooting_star() {
  # Random edge start
  local edge=$(( RANDOM % 4 ))
  local x y vx vy
  
  case $edge in
    0) # Top
      x=$(( RANDOM % cols ))
      y=0
      vx=$(( (RANDOM % 6) - 3 ))
      vy=$(( (RANDOM % 3) + 2 ))
      ;;
    1) # Right
      x=$((cols - 1))
      y=$(( RANDOM % (lines - 1) ))
      vx=$(( -(RANDOM % 3) - 2 ))
      vy=$(( (RANDOM % 6) - 3 ))
      ;;
    2) # Bottom
      x=$(( RANDOM % cols ))
      y=$((lines - 2))
      vx=$(( (RANDOM % 6) - 3 ))
      vy=$(( -(RANDOM % 3) - 2 ))
      ;;
    3) # Left
      x=0
      y=$(( RANDOM % (lines - 1) ))
      vx=$(( (RANDOM % 3) + 2 ))
      vy=$(( (RANDOM % 6) - 3 ))
      ;;
  esac
  
  shooting_stars+=("$x,$y,$vx,$vy,10")  # x,y,vx,vy,trail_length
}

# Update shooting stars
update_shooting_stars() {
  local new_shooting_stars=()
  
  for star in "${shooting_stars[@]}"; do
    IFS=',' read -r x y vx vy trail <<< "$star"
    
    # Clear old position
    for ((t=0; t<trail && t<10; t++)); do
      local tx=$((x - vx * t))
      local ty=$((y - vy * t))
      [[ $tx -ge 0 && $tx -lt $cols && $ty -ge 0 && $ty -lt $((lines-1)) ]] && \
        echo -ne "\e[${ty};${tx}H "
    done
    
    # Move
    x=$((x + vx))
    y=$((y + vy))
    
    # Draw if on screen
    if [[ $x -ge 0 && $x -lt $cols && $y -ge 0 && $y -lt $((lines-1)) ]]; then
      # Draw trail
      for ((t=0; t<trail && t<10; t++)); do
        local tx=$((x - vx * t))
        local ty=$((y - vy * t))
        if [[ $tx -ge 0 && $tx -lt $cols && $ty -ge 0 && $ty -lt $((lines-1)) ]]; then
          local fade=$((2 - t/3))
          [[ $fade -lt 0 ]] && fade=0
          if [[ $t -eq 0 ]]; then
            echo -ne "\e[${ty};${tx}H\e[1;33m⭐\e[0m"
          else
            echo -ne "\e[${ty};${tx}H\e[${fade};33m═\e[0m"
          fi
        fi
      done
      new_shooting_stars+=("$x,$y,$vx,$vy,$trail")
    fi
  done
  
  shooting_stars=("${new_shooting_stars[@]}")
}

# Draw constellations
draw_constellations() {
  [[ "$constellation" != "true" ]] && return
  
  for group in "${constellation_groups[@]}"; do
    [[ -z "$group" ]] && continue
    
    # Split into points and connections
    IFS='|' read -r point_data connection_data <<< "$group"
    local points=($point_data)
    
    # Draw constellation points
    for point in "${points[@]}"; do
      IFS=',' read -r x y <<< "$point"
      if [[ $x -ge 0 && $x -lt $cols && $y -ge 0 && $y -lt $((lines-1)) ]]; then
        echo -ne "\e[${y};${x}H\e[1;36m✦\e[0m"
      fi
    done
    
    # Draw connections
    IFS=',' read -ra connections <<< "$connection_data"
    for conn in "${connections[@]}"; do
      IFS='-' read -r idx1 idx2 <<< "$conn"
      
      # Get the two points to connect
      IFS=',' read -r x1 y1 <<< "${points[$idx1]}"
      IFS=',' read -r x2 y2 <<< "${points[$idx2]}"
      
      # Draw line between points
      local dx=$((x2 - x1))
      local dy=$((y2 - y1))
      local steps=$(( ${dx#-} > ${dy#-} ? ${dx#-} : ${dy#-} ))
      [[ $steps -eq 0 ]] && steps=1
      
      for ((s=1; s<steps; s++)); do
        local lx=$((x1 + dx * s / steps))
        local ly=$((y1 + dy * s / steps))
        if [[ $lx -ge 0 && $lx -lt $cols && $ly -ge 0 && $ly -lt $((lines-1)) ]]; then
          echo -ne "\e[${ly};${lx}H\e[2;36m·\e[0m"
        fi
      done
    done
  done
}

# Draw a single star
draw_star() {
  IFS=',' read -r x y brightness color lifetime trail_length vx vy <<< "$1"
  
  # Monotone mode color override
  [[ "$monotone" == "true" ]] && color=37
  
  if [[ "$lightspeed" == "true" ]] || [[ "$gravity" == "true" ]]; then
    # Draw star trail during lightspeed/gravity
    center_x=$(( cols / 2 ))
    center_y=$(( (lines - 1) / 2 ))
    
    # Calculate direction from center
    dx=$(( x - center_x ))
    dy=$(( y - center_y ))
    
    # Draw trail
    for ((t=0; t<=trail_length && t<10; t++)); do
      trail_x=$(( x - (dx * t / 10) ))
      trail_y=$(( y - (dy * t / 10) ))
      
      # Ensure within bounds
      if [[ $trail_x -ge 0 && $trail_x -lt $cols && $trail_y -ge 0 && $trail_y -lt $((lines-1)) ]]; then
        if [[ $t -eq 0 ]]; then
          echo -ne "\e[${trail_y};${trail_x}H\e[1;${color}m●\e[0m"
        else
          fade=$(( 2 - (t / 4) ))
          [[ $fade -lt 0 ]] && fade=0
          echo -ne "\e[${trail_y};${trail_x}H\e[${fade};${color}m━\e[0m"
        fi
      fi
    done
  else
    # Normal star drawing
    if [[ $y -lt $((lines-1)) ]]; then
      case $brightness in
        0) echo -ne "\e[${y};${x}H\e[2;${color}m·\e[0m" ;;  # Dim
        1) echo -ne "\e[${y};${x}H\e[0;${color}m*\e[0m" ;;  # Normal
        2) echo -ne "\e[${y};${x}H\e[1;${color}m✦\e[0m" ;;  # Bright
        3) echo -ne "\e[${y};${x}H " ;;                     # Hidden
      esac
    fi
  fi
}

# Clear a star's position (with trail if needed)
clear_star() {
  IFS=',' read -r x y brightness color lifetime trail_length vx vy <<< "$1"
  
  if [[ "$lightspeed" == "true" ]] || [[ "$gravity" == "true" ]]; then
    center_x=$(( cols / 2 ))
    center_y=$(( (lines - 1) / 2 ))
    dx=$(( x - center_x ))
    dy=$(( y - center_y ))
    
    # Clear entire trail
    for ((t=0; t<=trail_length && t<10; t++)); do
      trail_x=$(( x - (dx * t / 10) ))
      trail_y=$(( y - (dy * t / 10) ))
      if [[ $trail_x -ge 0 && $trail_x -lt $cols && $trail_y -ge 0 && $trail_y -lt $((lines-1)) ]]; then
        echo -ne "\e[${trail_y};${trail_x}H "
      fi
    done
  else
    [[ $y -lt $((lines-1)) ]] && echo -ne "\e[${y};${x}H "
  fi
}

# Check for keypresses
check_input() {
  local key
  IFS= read -r -s -n 1 -t 0.001 key 2>/dev/null || true
  
  case "$key" in
    m) monotone=$([[ "$monotone" == "true" ]] && echo "false" || echo "true") ;;
    t) 
      if [[ "$lightspeed" == "true" ]]; then
        lightspeed=false
        clear
        init_stars
        init_planets
      else
        lightspeed=true
        gravity=false
        reverse=false
      fi
      ;;
    r)
      if [[ "$reverse" == "true" ]]; then
        reverse=false
        clear
        init_stars
        init_planets
      else
        reverse=true
        lightspeed=true
        gravity=false
      fi
      ;;
    g)
      if [[ "$gravity" == "true" ]]; then
        gravity=false
        clear
        init_stars
        init_planets
      else
        gravity=true
        lightspeed=false
        reverse=false
      fi
      ;;
    " ") paused=$([[ "$paused" == "true" ]] && echo "false" || echo "true") ;;
    c) 
      constellation=$([[ "$constellation" == "true" ]] && echo "false" || echo "true")
      if [[ "$constellation" == "true" ]]; then
        generate_constellations
      else
        clear
        init_stars
        init_planets
      fi
      ;;
    p)
      planets=$([[ "$planets" == "true" ]] && echo "false" || echo "true")
      if [[ "$planets" == "true" ]]; then
        init_planets
      else
        clear
        init_stars
      fi
      ;;
    B) show_status=$([[ "$show_status" == "true" ]] && echo "false" || echo "true") ;;
    S) auto_shooting=$([[ "$auto_shooting" == "true" ]] && echo "false" || echo "true") ;;
    s) create_shooting_star ;;
    h|'?') 
      show_help=$([[ "$show_help" == "true" ]] && echo "false" || echo "true")
      [[ "$show_help" == "false" ]] && clear && init_stars && init_planets
      ;;
    +)
      [[ $density -gt 3 ]] && density=$((density - 1))
      clear
      init_stars
      init_planets
      ;;
    -)
      [[ $density -lt 20 ]] && density=$((density + 1))
      clear
      init_stars
      init_planets
      ;;
    ,)
      speed=$(echo "$speed + 0.02" | bc)
      [[ $(echo "$speed > 0.5" | bc) -eq 1 ]] && speed=0.5
      ;;
    .)
      speed=$(echo "$speed - 0.02" | bc)
      [[ $(echo "$speed < 0.02" | bc) -eq 1 ]] && speed=0.02
      ;;
    q|$'\e') exit 0 ;;
  esac
}

# Main loop
init_stars
shooting_stars=()
frame_counter=0

while true; do
  # Check for input
  check_input
  
  # Update terminal size
  new_cols=$(tput cols)
  new_lines=$(tput lines)
  [[ "$new_cols" != "$cols" || "$new_lines" != "$lines" ]] && {
    cols=$new_cols
    lines=$new_lines
    clear
    init_stars
    init_planets
    [[ "$constellation" == "true" ]] && generate_constellations
  }
  
  # Draw status bar always (if enabled)
  draw_status
  [[ "$show_help" == "true" ]] && draw_help
  
  # PAUSE CHECK - Skip everything if paused
  if [[ "$paused" == "true" ]]; then
    sleep "$speed"
    continue
  fi
  
  # Clear screen periodically for constellation mode
  if [[ "$constellation" == "true" ]]; then
    frame_counter=$((frame_counter + 1))
    if [[ $((frame_counter % 150)) -eq 0 ]]; then
      clear
      generate_constellations  # New random constellations
      init_planets
    fi
  fi
  
  # Occasionally spawn shooting stars if auto mode is on
  [[ "$auto_shooting" == "true" ]] && [[ $(( RANDOM % 100 )) -lt 2 ]] && [[ ${#shooting_stars[@]} -lt 3 ]] && create_shooting_star
  
  # Update shooting stars
  update_shooting_stars
  
  # Draw planets first (background)
  draw_planets
  
  # Draw constellations (background)
  draw_constellations
  
  # Update each star
  for i in "${!stars[@]}"; do
    IFS=',' read -r x y brightness color lifetime trail_length vx vy <<< "${stars[$i]}"
    
    # Clear old position
    clear_star "${stars[$i]}"
    
    if [[ "$lightspeed" == "true" ]] || [[ "$gravity" == "true" ]]; then
      # Movement calculations
      center_x=$(( cols / 2 ))
      center_y=$(( (lines - 1) / 2 ))
      
      dx=$(( x - center_x ))
      dy=$(( y - center_y ))
      
      if [[ "$gravity" == "true" ]]; then
        # Spiral movement
        dist_sq=$(( dx*dx + dy*dy ))
        [[ $dist_sq -eq 0 ]] && dist_sq=1
        
        # Tangential velocity for spiral
        vx=$(( -dy / 20 ))
        vy=$(( dx / 20 ))
        
        # Radial velocity (inward)
        vx=$(( vx - dx / 50 ))
        vy=$(( vy - dy / 50 ))
        
        x=$(( x + vx ))
        y=$(( y + vy * 2 ))  # Aspect ratio compensation
        
# Respawn if too close to center
       if [[ $dist_sq -lt 100 ]]; then
         angle=$(( RANDOM % 360 ))
         radius=$(( RANDOM % 30 + 20 ))
         x=$(( center_x + radius ))
         y=$(( center_y + (RANDOM % radius - radius/2) ))
         trail_length=0
         color=$(( RANDOM % 7 + 31 ))
       fi
     else
       # Lightspeed movement
       if [[ "$reverse" == "true" ]]; then
         # Inward movement
         x=$(( x - (dx / 10) ))
         y=$(( y - (dy * 2 / 10) ))
         
         # Respawn at edges when too close to center
         if [[ ${dx#-} -lt 5 && ${dy#-} -lt 3 ]]; then
           edge=$(( RANDOM % 4 ))
           case $edge in
             0) x=$(( RANDOM % cols )); y=0 ;;
             1) x=$(( RANDOM % cols )); y=$((lines - 2)) ;;
             2) x=0; y=$(( RANDOM % (lines - 1) )) ;;
             3) x=$((cols - 1)); y=$(( RANDOM % (lines - 1) )) ;;
           esac
           trail_length=0
           color=$(( RANDOM % 7 + 31 ))
         fi
       else
         # Outward movement
         x=$(( x + (dx / 10) ))
         y=$(( y + (dy * 2 / 10) ))
         
         # Respawn at center when off screen
         if [[ $x -lt 0 || $x -ge $cols || $y -lt 0 || $y -ge $((lines-1)) ]]; then
           x=$(( center_x + (RANDOM % 40 - 20) ))
           y=$(( center_y + (RANDOM % 20 - 10) ))
           trail_length=0
           color=$(( RANDOM % 7 + 31 ))
         fi
       fi
     fi
     
     # Increase trail length
     trail_length=$(( trail_length < 10 ? trail_length + 1 : 10 ))
   else
     # Normal mode behavior
     trail_length=0
     vx=0
     vy=0
     
     # Decrease lifetime
     lifetime=$(( lifetime - 1 ))
     
     # Respawn star in new location when lifetime expires or randomly
     if [[ $lifetime -le 0 ]] || (( RANDOM % 100 < respawn_chance )); then
       x=$(( RANDOM % cols ))
       y=$(( RANDOM % (lines - 1) ))
       brightness=$(( RANDOM % 3 ))
       color=$(( RANDOM % 7 + 31 ))
       lifetime=$(( RANDOM % 50 + 20 ))
     else
       # Just twinkle in place
       if (( RANDOM % 100 < twinkle_chance )); then
         case $brightness in
           0) new_brightness=$(( RANDOM % 2 )) ;;
           1) new_brightness=$(( RANDOM % 3 )) ;;
           2) new_brightness=$(( RANDOM % 2 + 1 )) ;;
           3) new_brightness=$(( RANDOM % 2 )) ;;
         esac
         (( RANDOM % 100 < 5 )) && new_brightness=3
         brightness=$new_brightness
       fi
     fi
   fi
   
   # Update star data
   stars[$i]="$x,$y,$brightness,$color,$lifetime,$trail_length,$vx,$vy"
   
   # Draw star
   draw_star "${stars[$i]}"
 done
 
 sleep "$speed"
done
