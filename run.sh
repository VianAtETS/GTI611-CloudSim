#!/bin/bash
# Usage:
#   ./run.sh                      -> partie2_E26 scenario 1 (default)
#   ./run.sh partie2_E26 3        -> partie2_E26 scenario 3 (arg passed to main)
#   ./run.sh ThrMmt               -> upstream planetlab algorithm (Partie 3)
#   ./run.sh LrrMmt_S8            -> custom planetlab variant (Partie 4)
#   ./run.sh org.cloudbus...Foo   -> fully-qualified class
#
# Custom .java files (partie2_E26.java, Lrr*_S*.java) live at the repo root and
# are copied into the cloudsim submodule tree at run time, so the submodule
# stays unmodified.
set -e

CLASS_SHORT=${1:-"partie2_E26"}
EXEC_ARG=${2:-""}
BASE="org.cloudbus.cloudsim.examples"
WORKSPACE="/workspaces/GTI611-CloudSim"
EXAMPLES_ROOT="$WORKSPACE/cloudsim/modules/cloudsim-examples/src/main/java/org/cloudbus/cloudsim/examples"
PLANETLAB_DST="$EXAMPLES_ROOT/power/planetlab"

if [[ "$CLASS_SHORT" == *.* ]]; then
    # Fully-qualified class name, no copy.
    MAIN_CLASS="$CLASS_SHORT"
elif [[ "$CLASS_SHORT" == partie* ]]; then
    # Lives in examples root package.
    MAIN_CLASS="${BASE}.${CLASS_SHORT}"
    SRC_FILE="$WORKSPACE/${CLASS_SHORT}.java"
    [[ -f "$SRC_FILE" ]] && cp "$SRC_FILE" "$EXAMPLES_ROOT/"
elif [[ "$CLASS_SHORT" == Lrr*_S* ]]; then
    # Custom Partie 4 variant in the power.planetlab package.
    MAIN_CLASS="${BASE}.power.planetlab.${CLASS_SHORT}"
    SRC_FILE="$WORKSPACE/${CLASS_SHORT}.java"
    [[ -f "$SRC_FILE" ]] && cp "$SRC_FILE" "$PLANETLAB_DST/"
else
    # Upstream planetlab algorithm (ThrMmt, MadMu, IqrRs, LrrMmt, ...).
    MAIN_CLASS="${BASE}.power.planetlab.${CLASS_SHORT}"
fi

cd "$WORKSPACE/cloudsim"
mvn -pl modules/cloudsim-examples -am install -DskipTests -q

if [[ -n "$EXEC_ARG" ]]; then
    mvn -pl modules/cloudsim-examples exec:java \
        -Dexec.mainClass="$MAIN_CLASS" \
        -Dexec.args="$EXEC_ARG" \
        -Dmaven.resources.skip=true
else
    mvn -pl modules/cloudsim-examples exec:java \
        -Dexec.mainClass="$MAIN_CLASS" \
        -Dmaven.resources.skip=true
fi
