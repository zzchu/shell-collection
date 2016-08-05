#!/bin/sh

set -x
if [ $# -gt 4 -o $# -lt 2 ]; then
echo "*please use command $0 output_filename input_folder0 [input_folder1] [input_folder2]"
echo "*example: $0 libwebrtc_libs.a ./Release-iphoneos/armv7 ./Release-iphoneos/arm64"
exit 2
fi

base_dir=$(dirname "$0")
current_dir=`pwd`
ws_dir=${current_dir}/${base_dir}

target_file=${current_dir}/$1

abs_path=`pwd`

function convertToABSPath() {
DIRNAME=$1
if [ "${DIRNAME:0:1}" = "/" ];then
abs_path=$DIRNAME
else
abs_path="`pwd`"/$DIRNAME
fi
}

function merge_libs() {
mkdir ${ws_dir}/temp_folder
cd ${ws_dir}/temp_folder
find $2 -maxdepth 1 -name "*.a" > filenamelist.txt

while read line
do
ar -x ${line}
done < filenamelist.txt

libtool -static -o ../${1} *.o
cd ..
rm -fr temp_folder
}



if [ $# -eq 2 ]; then
convertToABSPath $2
input_folder0=${abs_path}
merge_libs arch0_libs.a ${input_folder0}
cd ${ws_dir}
mv arch0_libs.a ${target_file}

elif [ $# -eq 3 ]; then
convertToABSPath $2
input_folder0=${abs_path}
merge_libs arch0_libs.a ${input_folder0}
convertToABSPath $3
input_folder1=${abs_path}
merge_libs arch1_libs.a ${input_folder1}
cd ${ws_dir}
lipo -create -output ${target_file} arch0_libs.a arch1_libs.a

elif [ $# -eq 4 ]; then

convertToABSPath $2
input_folder0=${abs_path}
merge_libs arch0_libs.a ${input_folder0}
convertToABSPath $3
input_folder1=${abs_path}
merge_libs arch1_libs.a ${input_folder1}
convertToABSPath $4
input_folder2=${abs_path}
merge_libs arch2_libs.a ${input_folder2}
cd ${ws_dir}
lipo -create -output ${target_file} arch0_libs.a arch1_libs.a arch2_libs.a
fi


exit 0
