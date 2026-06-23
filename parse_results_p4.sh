#!/bin/bash
# Extracts Partie 4 metrics from the LrrMmt_S*/LrrMu_S* logs and prints a CSV.
#
# One row per (algorithm, scenario). Columns cover Tableaux 8 & 9.
#   alg, scenario, nodes, vms, total_time, energy, migrations, sla, sla_host,
#   sla_avg, shutdowns, t_before_shutdown, mig_time, sel_vm, sel_host, realloc
#
# Usage: ./parse_results_p4.sh > resultats_partie4.csv

LOGS="/workspaces/GTI611-CloudSim/logs"

num() { grep -oP "$1" "$2" 2>/dev/null | head -1; }

echo "alg,scenario,nodes,vms,total_time,energy,migrations,sla,sla_host,sla_avg,shutdowns,t_before_shutdown,mig_time,sel_vm,sel_host,realloc"

for alg in LrrMmt LrrMu; do
    for s in 7 8 9; do
        log="$LOGS/${alg}_S${s}.log"
        if [[ ! -f "$log" ]]; then
            echo "$alg,$s,,,,,,,,,,,,,,"
            continue
        fi

        nodes=$(      num '(?<=Number of hosts: )\d+'                  "$log")
        vms=$(        num '(?<=Number of VMs: )\d+'                    "$log")
        total_time=$( num '(?<=Total simulation time: )[\d.]+'        "$log")
        energy=$(     num '(?<=Energy consumption: )[\d.]+'           "$log")
        migrations=$( num '(?<=Number of VM migrations: )\d+'        "$log")
        sla=$(        num '(?<=^SLA: )[\d.]+'                          "$log")
        sla_host=$(   num '(?<=SLA time per active host: )[\d.]+'    "$log")
        sla_avg=$(    num '(?<=Average SLA violation: )[\d.]+'       "$log")
        shutdowns=$(  num '(?<=Number of host shutdowns: )\d+'      "$log")
        t_shutdown=$( num '(?<=Mean time before a host shutdown: )[\d.]+' "$log")
        mig_time=$(   num '(?<=Mean time before a VM migration: )[\d.]+'  "$log")
        sel_vm=$(     num '(?<=VM selection mean: )[\d.]+'          "$log")
        sel_host=$(   num '(?<=host selection mean: )[\d.]+'        "$log")
        realloc=$(    num '(?<=VM reallocation mean: )[\d.]+'       "$log")

        echo "$alg,$s,$nodes,$vms,$total_time,$energy,$migrations,$sla,$sla_host,$sla_avg,$shutdowns,$t_shutdown,$mig_time,$sel_vm,$sel_host,$realloc"
    done
done
