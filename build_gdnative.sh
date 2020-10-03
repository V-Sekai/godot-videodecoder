#! /bin/bash

# usage: ADDON_BIN_DIR=$PWD/godot/addons/bin ./contrib/godot-videodecoder/build_gdnative.sh
# (from within your project where this is a submodule installed at ./contrib/godot-videodecoder/build_gdnative.sh/)

# The Dockerfile will run a container to compile everything:
# http://docs.godotengine.org/en/3.2/development/compiling/compiling_for_x11.html
# http://docs.godotengine.org/en/3.2/development/compiling/compiling_for_windows.html#cross-compiling-for-windows-from-other-operating-systems

DIR="$(cd $(dirname "$0") && pwd)"
DOCKER="$(which podman || which docker)"
ADDON_BIN_DIR=${ADDON_BIN_DIR:-$DIR/target}
JOBS=${JOBS:-4}
if [ -f /proc/cpuinfo ]; then
    JOBS=$(echo "$(cat /proc/cpuinfo  | grep processor |wc -l) - 1" |  bc -l)
elif type sysctl > /dev/null; then
    # osx logical cores
    JOBS=$(sysctl -n hw.ncpu)
else
    echo "Unable to determine how many logical cores are available."
    echo "Using JOBS=$JOBS"
fi
echo "Using JOBS=$JOBS"

set -x
# precreate the target directory because otherwise
# docker cp will copy x11/* -> $ADDON_BIN_DIR/* instead of x11/* -> $ADDON_BIN_DIR/x11/*
mkdir -p $ADDON_BIN_DIR/

set -e
# # use xenial for linux
# (for ubuntu 16 compatibility even though it's outdated already)
$DOCKER build ./ -f Dockerfile.x11 --build-arg JOBS=$JOBS -t "godot-videodecoder-x11"
echo "extracting $ADDON_BIN_DIR/x11"
id=$($DOCKER create godot-videodecoder-x11)
$DOCKER cp $id:/opt/target/x11 $ADDON_BIN_DIR/
$DOCKER rm -v $id

# focal is for cross compiles
$DOCKER build ./ -f Dockerfile.win64 --build-arg JOBS=$JOBS -t "godot-videodecoder-win64"
echo "extracting $ADDON_BIN_DIR/win64"
id=$(docker create godot-videodecoder-win64)
$DOCKER cp $id:/opt/target/win64 $ADDON_BIN_DIR/
$DOCKER rm -v $id

