#!/bin/bash
set -x
#path to webrtc source code root folder
base_dir=$(dirname "$0")
current_dir=`pwd`
ws_dir=${current_dir}/${base_dir}
#cd $base_dir/src
#echo $ws_dir

function updateToReleaseBranch() {
cd $ws_dir/src
export GYP_DEFINES="OS=ios"
fetch --nohooks webrtc_ios
gclient sync
git checkout -b $1 branch-heads/$1
gClient sync
}


function wrios() {
export GYP_DEFINES="$GYP_DEFINES OS=ios"
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

function wrsim() {
wrios
export GYP_DEFINES="$GYP_DEFINES target_arch=ia32"
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



function generate_include_file_structure() {
rm -fr $ws_dir/webrtc_includes
mkdir -p $ws_dir/webrtc_includes
cp -fr $ws_dir/src/webrtc/* $ws_dir/webrtc_includes
cd $ws_dir/webrtc_includes
rm -fr androidjunit build examples test tools
find . ! -name "*.h" -type f -exec rm -f {} \;
deleteempty
}




#set the default configuration
#ARGS=`getopt -o a:g:xb:i $*`

if [ $# -lt 1 ]; then
echo "*please use command $0 -a [ios32/ios64/ios_sim] <-g [git_branch_name]> <-x> <-b [Debug/Release-iphonesimulator/iphoneos]> <-i>"
echo "*-a: architecture"
echo "*-g: get a new branch code"
echo "*-x: generate the xcode project"
echo "*-b: generate the binary file"
echo "*-i: generate the include file structure"
echo "*example $0 -a ios64 -g 53 -x -b Release-iphoneos -i"
exit 2
fi


arch="NO"
branch_name="NO"
gen_xcode="NO"
binary_mode="NO"
gen_include="NO"

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
    echo "*please use command $0 -a [ios32/ios64/ios_sim] <-g> <-x> <-b [Debug/Release-iphonesimulator/iphoneos]> <-i>"
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
wrios32
elif [ "ios64" = "${arch}" ]; then
wrios64
elif [ "ios_sim" = "${arch}" ]; then
wrsim
else
echo arch are illegal!!!, please have a check.
exit 2
fi
fi

if [ "NO" != "${gen_xcode}" ]; then
echo "start to generate the xcode project .............."
export GYP_GENERATORS="xcode,xcode-ios"
python ${ws_dir}/src/webrtc/build/gyp_webrtc.py
fi


if [ "NO" != "${binary_mode}" ]; then
echo "start to build the binary file with mode :${binary_mode} ............ "
rm -fr ${ws_dir}/src/out_ios/${binary_mode}
python ${ws_dir}/src/webrtc/build/gyp_webrtc.py
cd ${ws_dir}/src
ninja -C out_ios/${binary_mode} AppRTCDemo
fi

if [ "NO" != "${gen_include}" ]; then
echo "start to generate the webrtc include files ..........."
generate_include_file_structure

fi

exit 0