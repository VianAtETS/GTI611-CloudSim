#!/bin/bash
# Runs every CloudSim simulation needed for GTI611 Lab 2.
# Build once, then run exec:java in parallel.
# Logs: ./logs/<name>.log
#
# Custom sources (partie2_E26.java, Lrr*_S*.java) are copied into the submodule
# tree before the build so they compile alongside the upstream examples.

set -euo pipefail

WORKSPACE="/workspaces/GTI611-CloudSim"
LOGS="$WORKSPACE/logs"
CLOUDSIM="$WORKSPACE/cloudsim"
BASE="org.cloudbus.cloudsim.examples"
EXAMPLES_ROOT="$CLOUDSIM/modules/cloudsim-examples/src/main/java/org/cloudbus/cloudsim/examples"
PLANETLAB_DST="$EXAMPLES_ROOT/power/planetlab"
MAX_JOBS=$(( $(nproc) > 1 ? $(nproc) - 1 : 1 ))

mkdir -p "$LOGS"

echo "==> Copying custom sources into the submodule tree..."
[[ -f "$WORKSPACE/partie2_E26.java" ]] && cp "$WORKSPACE/partie2_E26.java" "$EXAMPLES_ROOT/"
for f in "$WORKSPACE"/Lrr*_S*.java; do
    [[ -e "$f" ]] && cp "$f" "$PLANETLAB_DST/"
done

echo "==> Building (once)..."
cd "$CLOUDSIM"
mvn -pl modules/cloudsim-examples -am install -DskipTests -q
echo "==> Build OK -- up to $MAX_JOBS parallel simulations ($(nproc) cores)"
echo ""

run_sim() {
    local name="$1" main_class="$2" exec_args="${3:-}"
    if [[ -n "$exec_args" ]]; then
        mvn -pl modules/cloudsim-examples exec:java \
            -Dexec.mainClass="$main_class" \
            -Dexec.args="$exec_args" \
            -Dmaven.resources.skip=true \
            >"$LOGS/${name}.log" 2>&1 \
            && echo "[OK]  $name" || echo "[ERR] $name -- see $LOGS/${name}.log"
    else
        mvn -pl modules/cloudsim-examples exec:java \
            -Dexec.mainClass="$main_class" \
            -Dmaven.resources.skip=true \
            >"$LOGS/${name}.log" 2>&1 \
            && echo "[OK]  $name" || echo "[ERR] $name -- see $LOGS/${name}.log"
    fi
}

throttle() {
    while (( $(jobs -rp | wc -l) >= MAX_JOBS )); do
        wait -n 2>/dev/null || sleep 0.2
    done
}

# --- Partie 2: 4 scenarios TS/SS (sequential, same class, different arg) ---
echo "==> Partie 2 (4 scenarios)..."
for s in 1 2 3 4; do
    run_sim "partie2_E26_s${s}" "${BASE}.partie2_E26" "$s"
done
echo "==> Partie 2 done."
echo ""

# --- Partie 3: 9 upstream planetlab algorithms ---
echo "==> Partie 3 (9 algorithms)..."
for cls in ThrMmt ThrMu ThrRs MadMmt MadMu MadRs IqrMmt IqrMu IqrRs; do
    throttle
    run_sim "$cls" "${BASE}.power.planetlab.${cls}" &
done
wait
echo "==> Partie 3 done."
echo ""

# --- Partie 4: LrrMmt and LrrMu across workloads 20110303/06/22 ---
echo "==> Partie 4 (LrrMmt/LrrMu x 3 workloads)..."
for cls in LrrMmt_S7 LrrMmt_S8 LrrMmt_S9 LrrMu_S7 LrrMu_S8 LrrMu_S9; do
    throttle
    run_sim "$cls" "${BASE}.power.planetlab.${cls}" &
done
wait
echo "==> Partie 4 done."
echo ""

echo "All done. Logs in $LOGS/"
