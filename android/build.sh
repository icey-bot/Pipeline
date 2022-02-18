#!/bin/bash

if [ ! -n "$DEVICE" ]; then
    echo "What's for supper?"; exit 1;
fi

echo "--- Syncing"

cd /buildkite/src
grep -q $DEVICE out/last_device
if [ $? -gt 0 ]; then
    rm -rf .repo/local_manifests/*
fi
repo init -u https://github.com/Project-1CE/manifest -b sugisawa --depth 1
# repo forall -vc "git clean -fdx; git checkout -f"
repo sync -c -j$(nproc --all) --force-sync --fail-fast --no-clone-bundle --no-tags || exit 1

echo "--- Cleaning"

rm -rf out/target/product kernel/*/ship_prebuilt
grep -q $DEVICE out/last_device
if [ $? -gt 0 ]; then
    rm -rf out/
fi

echo "--- Building"

. build/envsetup.sh
lunch ice_${DEVICE}-userdebug || exit 1
echo ${DEVICE} > out/last_device

echo "--- Building"
mka installclean
mka bacon || exit 1

echo "--- Uploading"

meta_filename=$(ls out/target/product/${DEVICE}/Ice-sugisawa-*.zip | sed 's#.*/##')
meta_incr=$(cat out/target/product/${DEVICE}/ota_metadata | grep post-build-incremental | cut -c 24-)
meta_device=${DEVICE}
meta_version="sugisawa"
meta_romtype="nightly"
meta_sha256sum=$(cat out/target/product/${DEVICE}/${meta_filename}.sha256sum | awk '{ print $1 }')
meta_romsize=$(ls -la out/target/product/${DEVICE}/${meta_filename} | awk '{ print $5 }')
meta_url="https://otafsg-cost.project-ice.org/full/"${meta_device}"/"${meta_filename}
meta_datetime=$(cat out/target/product/${DEVICE}/ota_metadata | grep post-timestamp | cut -c 16-)

echo -e "--filename ${meta_filename} "'\\'"\n--incr ${meta_incr} "'\\'"\n--device ${meta_device} "'\\'"\n--version ${meta_version} "'\\'"\n--romtype ${meta_romtype} "'\\'"\n--sha256sum ${meta_sha256sum} "'\\'"\n--romsize ${meta_romsize} "'\\'"\n--url ${meta_url} "'\\'"\n--datetime ${meta_datetime}"
