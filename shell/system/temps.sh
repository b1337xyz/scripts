#!/bin/sh
# shellcheck disable=SC2086

# CPU?
# jq -r --arg a "amdgpu-pci-3000" \
#     'keys[] as $k | "\($k): \(.[$k][$a].edge.temp1_input) C \($a)"' \
#     sensors.json | sort -t : -k 4n | tail -5

db=~/.cache/sensors.json

case "$1" in
    top)
        n=${2:-5}
        printf '\n--- edge crit: 100\n'
        jq -r --arg a "amdgpu-pci-1200" 'keys[] as $k | 
            "\($k): \(.[$k][$a].edge.temp1_input) C \($a)"' \
             "$db" | sort -t : -k 4n | tail -$n

        printf '\n--- junction crit: 110\n'
        jq -r --arg a "amdgpu-pci-1200" 'keys[] as $k | 
            "\($k): \(.[$k][$a].junction.temp2_input) C \(.[$k][$a].PPT.power1_average) W"' \
             "$db" | sort -t : -k 4n | tail -$n


        printf '\n--- Tctl\n'
        jq -r --arg a "k10temp-pci-00c3" 'keys[] as $k | 
            "\($k): \(.[$k][$a].Tctl.temp1_input) C"' \
             "$db" | sort -t : -k 4n | tail -$n

        # printf '\n--- nvme\n'
        # jq -r --arg a "nvme-pci-2300" 'keys[] as $k | 
        #     "\($k): \(.[$k][$a].Composite.temp1_input) C"' \
        #      "$db" | sort -t : -k 4n | tail -8

        ;;
    *)
        n=${1:-5}
        printf '\n--- edge crit: 100\n'
        jq -r --arg a "amdgpu-pci-1200" 'keys[] as $k | 
            "\($k): \(.[$k][$a].edge.temp1_input) C \($a)"' \
             "$db"| tail -$n

        printf '\n--- junction crit: 110\n'
        jq -r --arg a "amdgpu-pci-1200" 'keys[] as $k | 
            "\($k): \(.[$k][$a].junction.temp2_input) C \(.[$k][$a].PPT.power1_average) W"' \
            "$db" | tail -$n

        printf '\n--- Tctl\n'
        jq -r --arg a "k10temp-pci-00c3" 'keys[] as $k | 
            "\($k): \(.[$k][$a].Tctl.temp1_input) C"' \
             "$db"| tail -$n

        ;;
esac
