#!/bin/bash

source ~/scripts/ansi_colors.sh

if [[ $# -eq 0 ]]; then
    printf '%b\n' "${RED}Use a switch name as an argument.${NC}"
    exit 1
fi

switchname="$1"
switchname_oob="${switchname/./-oob.}"
rack_serial=$(serf get name="$switchname" --fields=rack_serial | awk '{print $3}')
found_assets=$(ssh -q root@"$switchname_oob" "rackmonctl list" | grep -c ORV3)
or_check_output=$(or_check "$switchname" | awk 'NR > 2 {print $1, $2, $5, $NF}' | sed 's/^/| /')
serf_get_output=$(serf get -tn --fields=device_type,description rack_serial="$rack_serial",device_type=POWER_SHELF | sort | sed 's/^/| /')
# Formatting lines
BORDER='|------------------------------------------------------------|'
printf '\n'
printf '%b\n' "${UL_CYAN}Switchname: ${switchname}${NC}"
printf '%b\n' "${UL_CYAN}Switchname OOB: ${switchname_oob}${NC}"
printf '%b\n' "${UL_CYAN}Rack Serial: ${rack_serial}${NC}"
printf '\n'
printf '%s\n' "$BORDER"
printf '%b\n' "|${CYAN} Checking number of power shelves...${NC} (serf get)"
printf '%s\n' "$BORDER"
printf '%s\n' "$serf_get_output"
printf '%s\n' "$BORDER"
printf '%b\n' "|${CYAN} Number of found PSUs/BBUs:${NC} ${found_assets} (rackmonctl list)"
printf '%s\n' "$BORDER"
printf '%b\n' "|${CYAN} Retrieving list of found PSUs/BBUs...${NC} (or_check)"
printf '%s\n' "$BORDER"
printf '%s\n' "$or_check_output"
printf '%s\n' "$BORDER"
psu_found="$(grep -c "PSU" <<<"$or_check_output")"
bbu_found="$(grep -c "BBU" <<<"$or_check_output")"
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
    printf '%b\n' "|${GREEN} All PSUs/BBUs are present.${NC}"
else
    if [[ $psu_missing -gt 0 ]]; then
        printf '%b\n' "|${RED} ${psu_missing} PSUs are missing.${NC}"
    fi
    if [[ $bbu_missing -gt 0 ]]; then
        printf '%b\n' "|${RED} ${bbu_missing} BBUs are missing.${NC}"
    fi
    printf '%s\n' "$BORDER"
fi

printf '\n%b\n' "${BOLD_GREEN}Run Complete!${NC}"
