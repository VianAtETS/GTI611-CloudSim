#!/bin/bash
# Post-create setup for the CloudSim submodule workflow.
#
# The cloudsim source is a git submodule (see .gitmodules), checked out by the
# devcontainer's onCreateCommand/updateContentCommand. This script only
# configures Maven defaults and builds the submodule. It does NOT clone or
# delete any .git history -- doing so would break the submodule.
set -e

WORKSPACE=/workspaces/GTI611-CloudSim
CLOUDSIM="$WORKSPACE/cloudsim"

if [[ ! -d "$CLOUDSIM/modules" ]]; then
    echo "!! CloudSim submodule not initialized. Running submodule update..."
    git -C "$WORKSPACE" submodule update --init --depth 1
fi

echo "==> Configuring Maven defaults..."
mkdir -p "$CLOUDSIM/.mvn"
printf -- "-DskipTests\n-Dmaven.javadoc.skip=true\n" > "$CLOUDSIM/.mvn/maven.config"

echo "==> Building CloudSim (excluding distribution module)..."
cd "$CLOUDSIM"
mvn install -q -pl '!distribution'

echo "==> Done. Run a simulation with ./run.sh, or everything with ./run_all.sh"
