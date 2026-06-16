#!/bin/bash
# Extracts Part 3 metrics from all algorithm logs and prints a CSV.

LOGS="/workspaces/GTI611-CloudSim/logs"

ALGORITHMS="ThrMmt ThrMu ThrRs MadMmt MadMu MadRs IqrMmt IqrMu IqrRs"

extract() {
    grep -oP "(?<=${1}: ).*" "$2" | head -1 | tr -d ' '
}

echo "Algorithme,Energie (kWh),VMs migrées,SLA (%),SLA time/host actif (%),SLA violation moy (%),Hosts shutdown,Temps moy avant migration VM (s),Temps moy selection VM (s),stDev selection VM (s),Temps moy selection host (s),stDev selection host (s),Temps moy reallocation VM (s),stDev reallocation VM (s)"

for alg in $ALGORITHMS; do
    log="$LOGS/${alg}.log"
    if [[ ! -f "$log" ]]; then
        echo "$alg,N/A"
        continue
    fi

    energy=$(grep    "Energy consumption"          "$log" | grep -oP '[\d.]+(?= kWh)')
    migrations=$(grep "Number of VM migrations"    "$log" | grep -oP '\d+$')
    sla=$(grep        "^SLA:"                      "$log" | grep -oP '[\d.]+(?=%)')
    sla_host=$(grep   "SLA time per active host"   "$log" | grep -oP '[\d.]+(?=%)')
    sla_avg=$(grep    "Average SLA violation"      "$log" | grep -oP '[\d.]+(?=%)')
    shutdowns=$(grep  "Number of host shutdowns"   "$log" | grep -oP '\d+$')
    mig_time=$(grep   "Mean time before a VM mig"  "$log" | grep -oP '[\d.]+' | head -1)
    sel_vm=$(grep     "VM selection mean"          "$log" | grep -oP '[\d.]+' | head -1)
    sel_vm_sd=$(grep  "VM selection stDev"         "$log" | grep -oP '[\d.]+' | head -1)
    sel_host=$(grep   "host selection mean"        "$log" | grep -oP '[\d.]+' | head -1)
    sel_host_sd=$(grep "host selection stDev"      "$log" | grep -oP '[\d.]+' | head -1)
    realloc=$(grep    "VM reallocation mean"       "$log" | grep -oP '[\d.]+' | head -1)
    realloc_sd=$(grep "VM reallocation stDev"      "$log" | grep -oP '[\d.]+' | head -1)

    echo "$alg,$energy,$migrations,$sla,$sla_host,$sla_avg,$shutdowns,$mig_time,$sel_vm,$sel_vm_sd,$sel_host,$sel_host_sd,$realloc,$realloc_sd"
done
