#!/usr/bin/env bash
# Detail lines for the bar's hover cards: sysdetail.sh <cpu|mem|gpu>
temp() { for h in /sys/class/hwmon/hwmon*; do [ "$(cat $h/name 2>/dev/null)" = "$1" ] && [ -r $h/temp1_input ] && { echo $(( $(cat $h/temp1_input) / 1000 )); return; }; done; echo "--"; }
case "$1" in
cpu)
    echo "$(grep -m1 'model name' /proc/cpuinfo | sed 's/.*: //; s/ w\/.*//')"
    read -r l1 l5 l15 _ < /proc/loadavg
    echo "LOAD     $l1  $l5  $l15   ($(nproc) threads)"
    echo "TEMP     $(temp k10temp) C"
    echo "FREQ     $(awk '/cpu MHz/{s+=$4;n++}END{printf "%.0f MHz avg", s/n}' /proc/cpuinfo)"
    echo "PROFILE  $(powerprofilesctl get 2>/dev/null)"
    echo
    ps -eo pcpu,comm --sort=-pcpu --no-headers | head -5 | awk '{printf "%5.1f%%  %s\n", $1, $2}' ;;
mem)
    awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}/SwapTotal/{st=$2}/SwapFree/{sf=$2}/^Cached/{c=$2}
         END{printf "USED     %.1f / %.1f GiB\nCACHE    %.1f GiB\nSWAP     %.1f / %.1f GiB\n", (t-a)/1048576, t/1048576, c/1048576, (st-sf)/1048576, st/1048576}' /proc/meminfo
    echo
    ps -eo rss,comm --sort=-rss --no-headers | head -5 | awk '{printf "%5.1f GiB  %s\n", $1/1048576, $2}' ;;
gpu)
    for d in /sys/class/drm/card*/device; do
        [ -r $d/gpu_busy_percent ] || continue
        echo "RADEON (integrated)"
        echo "LOAD     $(cat $d/gpu_busy_percent)%"
        [ -r $d/mem_info_vram_used ] && echo "VRAM     $(( $(cat $d/mem_info_vram_used) / 1048576 )) / $(( $(cat $d/mem_info_vram_total) / 1048576 )) MiB"
        echo "TEMP     $(temp amdgpu) C"
    done
    echo
    echo "GEFORCE RTX 5060 (discrete)"
    nv=$(ls -d /sys/bus/pci/devices/*/ 2>/dev/null | while read -r p; do [ "$(cat $p/vendor 2>/dev/null)" = 0x10de ] && [ "$(cat $p/class 2>/dev/null | cut -c1-4)" = 0x03 ] && echo $p && break; done)
    st=$(cat "${nv}power/runtime_status" 2>/dev/null)
    if [ "$st" = active ]; then
        # only query the card when it is already awake, so hovering never wakes it
        nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw --format=csv,noheader,nounits 2>/dev/null |
            awk -F', ' '{printf "LOAD     %s%%\nVRAM     %s / %s MiB\nTEMP     %s C\nPOWER    %s W\n", $1, $2, $3, $4, $5}'
    else
        echo "STATE    asleep (saving power)"
    fi ;;
esac
