#!/bin/sh

set -x
if [ $# -gt 1]; then
echo "*please use command $0"
echo "*example: $0"
exit 2
fi

abs_path=`pwd`

function convertToABSPath() {
DIRNAME=$1
if [ "${DIRNAME:0:1}" = "/" ];then
abs_path=$DIRNAME
else
abs_path="`pwd`"/$DIRNAME
fi
}

base_dir=$(dirname "$0")
convertToABSPath $base_dir
ws_dir=${abs_path}


cd $ws_dir
bash webrtc_awesome.sh -a ios64 -b Release
bash webrtc_awesome.sh -a ios32 -b Release
bash webrtc_awesome.sh -a sim64 -b Release
bash webrtc_awesome.sh -a sim32 -b Release
bash webrtc_awesome.sh -a ios64 -b Debug
bash webrtc_awesome.sh -a ios32 -b Debug
bash webrtc_awesome.sh -a sim64 -b Debug
bash webrtc_awesome.sh -a sim32 -b Debug

lipo -create -output libwebrtc_libs_Release-iphoneos.a libwebrtc_libs_Release-iphoneos_ios64.a libwebrtc_libs_Release-iphoneos_ios32.a libwebrtc_libs_Release-iphonesimulator_sim32.a libwebrtc_libs_Release-iphonesimulator_sim64.a

lipo -create -output libwebrtc_libs_Debug-iphoneos.a libwebrtc_libs_Debug-iphoneos_ios64.a libwebrtc_libs_Debug-iphoneos_ios32.a libwebrtc_libs_Debug-iphonesimulator_sim32.a libwebrtc_libs_Debug-iphonesimulator_sim64.a


exit 0
