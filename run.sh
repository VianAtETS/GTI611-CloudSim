#!/bin/bash
# Usage: ./run.sh MadMmt
# Defaults to partie1_E26 if no argument given
CLASS_SHORT=${1:-"partie1_E26"}
PACKAGE="org.cloudbus.cloudsim.examples.power.planetlab"

cd /workspaces/GTI611-CloudSim/cloudsim
mvn -pl modules/cloudsim-examples compile exec:java \
  -Dexec.mainClass="${PACKAGE}.${CLASS_SHORT}" \
  -Dmaven.resources.skip=true
