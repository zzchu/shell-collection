#!/bin/bash
set -x
#path to webrtc source code root folder
base_dir=$(dirname "$0")
current_dir=`pwd`
ws_dir=${current_dir}/${base_dir}
#cd $base_dir/src
#echo $ws_dir

function updateToReleaseBranch() {
cd $ws_dir

if [ ! -d "./src" ]; then
echo "start to clone the webrtc source code"
export GYP_DEFINES="OS=ios"
fetch --nohooks webrtc_ios
gclient sync
fi

cd ./src
git checkout master
git fetch

isExist=`git branch | grep $1`
if [ "${isExist}x" = "x" ]; then
git checkout -b $1 branch-heads/$1
else
git checkout $1
fi

gClient sync
}


function wrios() {
export GYP_DEFINES="$GYP_DEFINES OS=ios clang_xcode=1 ios_deployment_target=9.0 use_objc_h264=1 rtc_use_h264=1 rtc_initialize_openh264=1"
export GYP_GENERATOR_FLAGS="$GYP_GENERATOR_FLAGS output_dir=out_ios"
}

function wrios32() {
wrios
export GYP_DEFINES="$GYP_DEFINES target_arch=arm"
#export GYP_GENERATORS="xcode,xcode-ios32"
}

function wrios64() {
wrios
export GYP_DEFINES="$GYP_DEFINES target_arch=arm64"
#export GYP_GENERATORS="xcode,xcode-ios64"
}

function wrsim32() {
wrios
export GYP_DEFINES="$GYP_DEFINES target_arch=ia32"
#export GYP_GENERATORS="xcode,xcode-ia32"
}

function wrsim64() {
wrios
export GYP_DEFINES="$GYP_DEFINES target_arch=x64"
#export GYP_GENERATORS="xcode,xcode-ia32"
}


deleteempty() {
find ${1:-.} -mindepth 1 -maxdepth 1 -type d | while read -r dir
do
if [[ -z "$(find "$dir" -mindepth 1 -type f)" ]] >/dev/null
then
echo "$dir"
rm -rf ${dir} 2>&- && echo "Empty, Deleted!" || echo "Delete error"
fi
if [ -d ${dir} ]
then
deleteempty "$dir"
fi
done
}

function exitOnFailure {
"$@"
status=${PIPESTATUS[0]}
if [ $status -ne 0 ]; then
echo "Error with command: $1"
exit $status
fi
return $status
}

function generate_include_file_structure() {
rm -fr $ws_dir/webrtc_includes
mkdir -p $ws_dir/webrtc_includes
cp -fr $ws_dir/src/webrtc/* $ws_dir/webrtc_includes
cd $ws_dir/webrtc_includes
rm -fr androidjunit build examples test tools
find . ! -name "*.h" -type f -exec rm -f {} \;
deleteempty .
}




#set the default configuration
#ARGS=`getopt -o a:g:xb:i $*`

if [ $# -lt 1 ]; then
echo "*please use command $0 -a [ios32/ios64/sim32/sim64] <-g [git_branch_name]> <-x> <-b [Debug/Release]> <-i>"
echo "*-a: architecture"
echo "*-g: get a new branch code"
echo "*-x: generate the xcode project"
echo "*-b: generate the binary file"
echo "*-i: generate the include file structure"
echo "*example $0 -a ios64 -g 53 -x -b Release -i"
exit 2
fi


arch="NO"
branch_name="NO"
gen_xcode="NO"
binary_mode="NO"
gen_include="NO"
ios_platform="NO"

build_arch="NO"

#set -- $ARGS
while getopts ":a:g:xb:i" opt
do
case "$opt"
in
    a)
    arch=$OPTARG
    ;;
    g)
    branch_name=$OPTARG
#    shift 2
    ;;
    x)
    gen_xcode="YES"
#    shift
    ;;
    b)
    binary_mode=$OPTARG
#    shift 2
    ;;
    i)
    gen_include="YES"
#    shift 2
    ;;
    ?)
    echo "*please use command $0 -a [ios32/ios64/sim32/sim64] <-g> <-x> <-b [Debug/Release]> <-i>"
    exit 1;;
esac
done

echo "arch=$arch, branch_name=$branch_name, gen_xcode=$gen_xcode, binary_mode=$binary_mode, gen_include=$gen_include"


if [ "NO" != "${branch_name}" ]; then
echo "start to get the new branch code: $branch_name .........."
updateToReleaseBranch ${branch_name}
fi

if [ "NO" != "${arch}" ]; then
if [ "ios32" = "${arch}" ]; then
build_arch="armv7"
wrios32
ios_platform="iphoneos"
elif [ "ios64" = "${arch}" ]; then
build_arch="arm64"
wrios64
ios_platform="iphoneos"
elif [ "sim32" = "${arch}" ]; then
build_arch="i386"
wrsim32
ios_platform="iphonesimulator"
elif [ "sim64" = "${arch}" ]; then
build_arch="x86_64"
wrsim64
ios_platform="iphonesimulator"
else
echo arch are illegal!!!, please have a check.
exit 2
fi
fi

if [ "NO" != "${binary_mode}" ]; then

rm -fr ${ws_dir}/src/out_ios/${binary_mode}-${ios_platform}

echo "generate the openh264 binary file"
#cd ${ws_dir}/src/third_party/openh264/src/codec/build/iOS/
cd ${ws_dir}/../../openh264/codec/build/iOS/

exitOnFailure xcodebuild ARCHS="${build_arch}" VALID_ARCHS="${build_arch}" ONLY_ACTIVE_ARCH=NO clean build -project dec/welsdec/welsdec.xcodeproj -target welsdec -configuration ${binary_mode} -sdk ${ios_platform} CONFIGURATION_BUILD_DIR="${ws_dir}/src/out_ios/${binary_mode}-${ios_platform}" >/dev/null 2>&1
exitOnFailure xcodebuild ARCHS="${build_arch}" VALID_ARCHS="${build_arch}" ONLY_ACTIVE_ARCH=NO clean build -project common/common.xcodeproj -target common -configuration ${binary_mode} -sdk ${ios_platform} CONFIGURATION_BUILD_DIR="${ws_dir}/src/out_ios/${binary_mode}-${ios_platform}" >/dev/null 2>&1

echo "start to build the binary file with mode :${binary_mode} ............ "
python ${ws_dir}/src/webrtc/build/gyp_webrtc.py
cd ${ws_dir}/src
exitOnFailure ninja -C out_ios/${binary_mode}-${ios_platform} AppRTCDemo


cd ${ws_dir}/src/out_ios/${binary_mode}-${ios_platform}
rm -fr libapprtc_common.a
rm -fr libapprtc_signaling.a
rm -fr libsocketrocket.a

cd ${ws_dir}
sh gen_webrtclibs.sh libwebrtc_libs_${binary_mode}-${ios_platform}_${arch}.a src/out_ios/${binary_mode}-${ios_platform}
fi

if [ "NO" != "${gen_xcode}" ]; then
echo "start to generate the xcode project .............."
export GYP_GENERATORS="xcode,xcode-ios"
python ${ws_dir}/src/webrtc/build/gyp_webrtc.py
fi


if [ "NO" != "${gen_include}" ]; then
echo "start to generate the webrtc include files ..........."
generate_include_file_structure

fi

exit 0
