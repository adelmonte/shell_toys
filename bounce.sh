while true; do
  cols=$(tput cols)
  lines=$(tput lines)
  for ((i=0; i<30; i++)); do
    x=$((RANDOM % cols))
    y=$((RANDOM % lines))
    echo -ne "\e[${y};${x}H*"
    sleep 0.1
    echo -ne "\e[${y};${x}H "
  done
done
