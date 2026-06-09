#!/bin/bash
set -e

WORKSPACE=/workspaces/GTI611-CloudSim

echo "==> Cloning CloudSim 4.0..."
git clone --depth=1 --branch cloudsim-4.0 \
  https://github.com/Cloudslab/cloudsim.git "$WORKSPACE/cloudsim"

echo "==> Configuring Maven defaults..."
mkdir -p "$WORKSPACE/cloudsim/.mvn"
printf -- "-DskipTests\n-Dmaven.javadoc.skip=true\n" \
  > "$WORKSPACE/cloudsim/.mvn/maven.config"

echo "==> Building CloudSim..."
cd "$WORKSPACE/cloudsim"
mvn install -q

echo "==> Done."
