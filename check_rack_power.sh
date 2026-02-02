#!/bin/bash

source ~/scripts/ansi_colors.sh

if [[ $# -eq 0 ]]; then
    echo "${RED}Use a switch name as an argument.${NC}"
    exit 1
fi

switchname="$1"
switchname_oob="${switchname/./-oob.}"
rack_serial=$(serf get name="$switchname" --fields=rack_serial | awk '{print $3}')
found_assets=$(ssh -q root@"$switchname_oob" "rackmonctl list" | grep ORV3 | wc -l)
or_check_output=$(or_check "$switchname" | awk 'NR > 2 {print $1, $2, $5, $NF}' | sed 's/^/| /')
serf_get_output=$(serf get -tn --fields=device_type,description rack_serial="$rack_serial",device_type=POWER_SHELF | sort | sed 's/^/| /')

printf "\n"
echo "${UL_CYAN}Switchname: $switchname${NC}"
echo "${UL_CYAN}Switchname OOB: $switchname_oob${NC}"
echo "${UL_CYAN}Rack Serial: $rack_serial${NC}"
printf "\n"
echo "|---------------------------------------------|"
echo "|${CYAN} Checking number of power shelves...${NC} (serf get)"
echo "|---------------------------------------------|"
echo "$serf_get_output"
echo "|---------------------------------------------|"
echo "|${CYAN} Number of found PSUs/BBUs:${NC}" "$found_assets (rackmonctl list)"
echo "|---------------------------------------------|"
echo "|${CYAN} Retrieving list of found PSUs/BBUs...${NC} (or_check)"
echo "|---------------------------------------------|"
echo "$or_check_output"
echo "|---------------------------------------------|"
psu_found=$(echo "$or_check_output" | grep "PSU" | wc -l)
bbu_found=$(echo "$or_check_output" | grep "BBU" | wc -l)
if [[ $(wc -l <<<"$serf_get_output") -eq 4 ]]; then
    expected_psu=12
    expected_bbu=12
elif [[ $(wc -l <<<"$serf_get_output") -eq 2 ]]; then
    expected_psu=6
    expected_bbu=6
else
    expected_psu=0
    expected_bbu=0
fi
psu_missing=$((expected_psu - psu_found))
bbu_missing=$((expected_bbu - bbu_found))
if [[ $psu_missing -le 0 && $bbu_missing -le 0 ]]; then
    echo "|${GREEN} All PSUs/BBUs are present.${NC}"
else
    if [[ $psu_missing -gt 0 ]]; then
        echo "|${RED} $psu_missing PSUs are missing.${NC}"
    fi
    if [[ $bbu_missing -gt 0 ]]; then
        echo "|${RED} $bbu_missing BBUs are missing.${NC}"
    fi
    echo "|---------------------------------------------|"
fi
printf "\n"
echo "${BOLD_GREEN}Run Complete!${NC}"
