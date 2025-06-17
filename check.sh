#!/bin/bash
cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
mem=$(free | awk '/Mem:/ {printf("%.0f", $3/$2*100)}')
disk=$(df / | awk '/\// {print $5}' | tr -d '%')
cat <<EOF
{"cpu": $cpu, "mem": $mem, "disk": $disk}
EOF
