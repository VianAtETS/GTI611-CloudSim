#!/bin/bash
# Runs all CloudSim simulations for GTI611 Lab 2.
# Build is done once; all exec:java calls then run in parallel.
# Logs: ./logs/<ClassName>.log

set -euo pipefail

WORKSPACE="/workspaces/GTI611-CloudSim"
LOGS="$WORKSPACE/logs"
CLOUDSIM="$WORKSPACE/cloudsim"
BASE="org.cloudbus.cloudsim.examples"
MAX_JOBS=$(( $(nproc) > 1 ? $(nproc) - 1 : 1 ))

mkdir -p "$LOGS"

echo "==> Building..."
cd "$CLOUDSIM"
mvn -pl modules/cloudsim-examples -am install -DskipTests -q
echo "==> Build OK — up to $MAX_JOBS parallel simulations ($(nproc) cores)"
echo ""

run_sim() {
    local name="$1" main_class="$2"
    mvn -pl modules/cloudsim-examples exec:java \
        -Dexec.mainClass="$main_class" \
        -Dmaven.resources.skip=true \
        >"$LOGS/${name}.log" 2>&1 \
        && echo "[OK]  $name" \
        || echo "[ERR] $name — see $LOGS/${name}.log"
}

throttle() {
    while (( $(jobs -rp | wc -l) >= MAX_JOBS )); do
        wait -n 2>/dev/null || sleep 0.2
    done
}

# --- Partie 2: 4 scenarios SS/TS ---
echo "==> Partie 2..."
run_sim "partie2_E26" "${BASE}.partie2_E26"
echo "==> Partie 2 done."
echo ""

# --- Partie 3: 9 planetlab algorithms (Thr, Mad, Iqr x Mmt, Mu, Rs) ---
echo "==> Partie 3..."
for cls in ThrMmt ThrMu ThrRs MadMmt MadMu MadRs IqrMmt IqrMu IqrRs; do
    throttle
    run_sim "$cls" "${BASE}.power.planetlab.${cls}" &
done
wait
echo "==> Partie 3 done."
echo ""

# --- Partie 4: LrrMmt and LrrMu (workload hardcoded in PlanetLabConstants.java) ---
echo "==> Partie 4 (default workload)..."
run_sim "LrrMmt" "${BASE}.power.planetlab.LrrMmt" &
run_sim "LrrMu"  "${BASE}.power.planetlab.LrrMu"  &
wait
echo "==> Partie 4 done."
echo ""

echo "All done. Logs in $LOGS/"
