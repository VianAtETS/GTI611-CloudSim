#!/bin/bash
# Usage: ./run.sh [ClassName]
# Defaults to partie1_E26 if no argument given.
# Fully qualified names are also accepted: ./run.sh org.cloudbus.cloudsim.examples.MyClass
set -e

CLASS_SHORT=${1:-"partie1_E26"}
BASE="org.cloudbus.cloudsim.examples"
WORKSPACE="/workspaces/GTI611-CloudSim"
EXAMPLES_SRC="$WORKSPACE/cloudsim/modules/cloudsim-examples/src/main/java/org/cloudbus/cloudsim/examples"

if [[ "$CLASS_SHORT" == *.* ]]; then
    MAIN_CLASS="$CLASS_SHORT"
elif [[ "$CLASS_SHORT" == partie* ]]; then
    MAIN_CLASS="${BASE}.${CLASS_SHORT}"
    SRC_FILE="$WORKSPACE/${CLASS_SHORT}.java"
    if [[ -f "$SRC_FILE" ]]; then
        cp "$SRC_FILE" "$EXAMPLES_SRC/"
    fi
else
    MAIN_CLASS="${BASE}.power.planetlab.${CLASS_SHORT}"
fi

cd "$WORKSPACE/cloudsim"
mvn -pl modules/cloudsim-examples -am install -DskipTests -q
mvn -pl modules/cloudsim-examples exec:java \
    -Dexec.mainClass="$MAIN_CLASS" \
    -Dmaven.resources.skip=true
