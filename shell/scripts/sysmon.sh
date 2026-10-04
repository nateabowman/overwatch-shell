#!/usr/bin/env bash
# Prints "<cpu%> <mem%> <gpu%> <nettype>:<connection>" every 2 seconds.
# GPU is the integrated Radeon's busy figure; the NVIDIA card is left asleep (see sysdetail.sh).
read -r _ u n s i w q sq st _ < /proc/stat
pt=$((u+n+s+i+w+q+sq+st)); pi=$((i+w)); k=0; net=""
gpuf=$(ls /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -1)
while :; do
    sleep 2
    read -r _ u n s i w q sq st _ < /proc/stat
    t=$((u+n+s+i+w+q+sq+st)); id=$((i+w)); dt=$((t-pt))
    cpu=$(( dt > 0 ? 100*(dt-(id-pi))/dt : 0 )); pt=$t; pi=$id
    mem=$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{printf "%d",100*(t-a)/t}' /proc/meminfo)
    gpu=0; [ -n "$gpuf" ] && read -r gpu < "$gpuf"
    if (( k % 5 == 0 )); then
        net=$(nmcli -t -f TYPE,STATE,CONNECTION device 2>/dev/null | awk -F: '$2=="connected" && $1!="loopback"{print $1":"$3; exit}')
    fi
    k=$((k+1))
    echo "$cpu $mem ${gpu:-0} ${net:-none:}"
done
