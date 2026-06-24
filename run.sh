#!/bin/bash
# Usage:
#   ./run.sh                      -> partie2_E26 scenario 1 (default)
#   ./run.sh partie2_E26 3        -> partie2_E26 scenario 3 (arg passed to main)
#   ./run.sh "partie2_E26 3"      -> also accepted (split internally)
#   ./run.sh ThrMmt               -> upstream planetlab algorithm (Partie 3)
#   ./run.sh LrrMmt_S8            -> custom planetlab variant (Partie 4)
#   ./run.sh org.cloudbus...Foo   -> fully-qualified class
#
# Flags:
#   --no-build   skip the Maven build (use after a first successful build to
#                save time; only safe if no .java source changed)
#
# Custom .java files (partie2_E26.java, Lrr*_S*.java) live at the repo root and
# are copied into the cloudsim submodule tree at run time, so the submodule
# stays unmodified.
set -e

BASE="org.cloudbus.cloudsim.examples"
WORKSPACE="/workspaces/GTI611-CloudSim"
EXAMPLES_ROOT="$WORKSPACE/cloudsim/modules/cloudsim-examples/src/main/java/org/cloudbus/cloudsim/examples"
PLANETLAB_DST="$EXAMPLES_ROOT/power/planetlab"

# Parse optional --no-build flag from anywhere in the args.
DO_BUILD=1
ARGS=()
for a in "$@"; do
    if [[ "$a" == "--no-build" ]]; then
        DO_BUILD=0
    else
        ARGS+=("$a")
    fi
done
set -- "${ARGS[@]}"

# Accept both `./run.sh partie2_E26 1` and `./run.sh "partie2_E26 1"`:
# if the first arg contains a space, split it into class + exec-arg.
CLASS_SHORT=${1:-"partie2_E26"}
EXEC_ARG=${2:-""}
if [[ "$CLASS_SHORT" == *" "* ]]; then
    read -r CLASS_SHORT EXEC_ARG <<< "$CLASS_SHORT"
fi

if [[ "$CLASS_SHORT" == *.* ]]; then
    MAIN_CLASS="$CLASS_SHORT"
elif [[ "$CLASS_SHORT" == partie* ]]; then
    MAIN_CLASS="${BASE}.${CLASS_SHORT}"
    SRC_FILE="$WORKSPACE/${CLASS_SHORT}.java"
    [[ -f "$SRC_FILE" ]] && cp "$SRC_FILE" "$EXAMPLES_ROOT/"
elif [[ "$CLASS_SHORT" == Lrr*_S* ]]; then
    MAIN_CLASS="${BASE}.power.planetlab.${CLASS_SHORT}"
    SRC_FILE="$WORKSPACE/${CLASS_SHORT}.java"
    [[ -f "$SRC_FILE" ]] && cp "$SRC_FILE" "$PLANETLAB_DST/"
else
    MAIN_CLASS="${BASE}.power.planetlab.${CLASS_SHORT}"
fi

echo "==> Classe : $MAIN_CLASS   (arg: '${EXEC_ARG:-<aucun>}')"

cd "$WORKSPACE/cloudsim"
if [[ "$DO_BUILD" == "1" ]]; then
    echo "==> Build (mvn install). Utilise --no-build pour sauter cette etape si rien n'a change."
    mvn -pl modules/cloudsim-examples -am install -DskipTests -q
fi

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
