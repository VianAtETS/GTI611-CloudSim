#!/bin/bash
# Extracts Partie 3 metrics from the algorithm logs and prints a CSV to stdout.
#
# Column order matches the Typst template (resultats_partie3.csv):
#   0  alg
#   1  energy        (kWh)
#   2  migrations
#   3  sla           (%)
#   4  sla_host      (%)  -- SLA time per active host
#   5  sla_avg       (%)  -- Average SLA violation
#   6  shutdowns
#   7  mig_time      (s)  -- Mean time before a VM migration
#   8  sel_vm        (s)  -- Execution time - VM selection mean
#   9  sel_vm_sd     (s)
#   10 sel_host      (s)  -- Execution time - host selection mean
#   11 sel_host_sd   (s)
#   12 realloc       (s)  -- Execution time - VM reallocation mean
#   13 realloc_sd    (s)
#
# Usage: ./parse_results.sh > resultats_partie3.csv

LOGS="/workspaces/GTI611-CloudSim/logs"
ALGORITHMS="ThrMmt ThrMu ThrRs MadMmt MadMu MadRs IqrMmt IqrMu IqrRs"

# field <regex-after-label> <logfile> : grabs the first number following a label.
num() { grep -oP "$1" "$2" 2>/dev/null | head -1; }

echo "alg,energy,migrations,sla,sla_host,sla_avg,shutdowns,mig_time,sel_vm,sel_vm_sd,sel_host,sel_host_sd,realloc,realloc_sd"

for alg in $ALGORITHMS; do
    log="$LOGS/${alg}.log"
    if [[ ! -f "$log" ]]; then
        echo "$alg,,,,,,,,,,,,,"
        continue
    fi

    energy=$(     num '(?<=Energy consumption: )[\d.]+'            "$log")
    migrations=$( num '(?<=Number of VM migrations: )\d+'         "$log")
    sla=$(        num '(?<=^SLA: )[\d.]+'                          "$log")
    sla_host=$(   num '(?<=SLA time per active host: )[\d.]+'     "$log")
    sla_avg=$(    num '(?<=Average SLA violation: )[\d.]+'        "$log")
    shutdowns=$(  num '(?<=Number of host shutdowns: )\d+'       "$log")
    mig_time=$(   num '(?<=Mean time before a VM migration: )[\d.]+' "$log")
    sel_vm=$(     num '(?<=VM selection mean: )[\d.]+'           "$log")
    sel_vm_sd=$(  num '(?<=VM selection stDev: )[\d.]+'          "$log")
    sel_host=$(   num '(?<=host selection mean: )[\d.]+'         "$log")
    sel_host_sd=$(num '(?<=host selection stDev: )[\d.]+'        "$log")
    realloc=$(    num '(?<=VM reallocation mean: )[\d.]+'        "$log")
    realloc_sd=$( num '(?<=VM reallocation stDev: )[\d.]+'       "$log")

    echo "$alg,$energy,$migrations,$sla,$sla_host,$sla_avg,$shutdowns,$mig_time,$sel_vm,$sel_vm_sd,$sel_host,$sel_host_sd,$realloc,$realloc_sd"
done
