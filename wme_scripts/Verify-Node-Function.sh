#!/bin/bash --login +x
set +x
ROOT=$WORKSPACE/$repo_loc/$pre_check_loc
cd $ROOT
git clean -dfx
git submodule init
git submodule update

###################################################
echo "$verify_node"
[ "$NODE_NAME" = "" ] && NODE_NAME=master
node=${NODE_NAME//-/_}
echo \$${node}_jobs
eval echo \$${node}_jobs
jobs=$(eval echo \$${node}_jobs)
echo "[INFO] Verify on $node: $jobs"

errstr=""


###################################################
## call cases to verify
parse_xml() {
res=$1
if [ ! -f $res ]; then
errstr="$errstr\n[ERR] cannot find the xml file!"
return 0
fi

check=`cat $res | grep "<testsuite"`
if [ $? -ne 0 ]; then
errstr="$errstr\n[ERR] no info at xml file:`basename $res`!"
return 0
fi

echo "[INFO] Start to parse unittest/ta results for `basename $res`"
fails=`cat $res | grep "<testsuite" | head -n 1 | awk -F " " '{print $3;}' | awk -F "\"" '{print $2;}'`
echo "[INFO] Failed number: $fails, xml: `basename $res`"
return $fails
}

function check_tool() {
[ $# -ne 1 ] && echo "[WARN] $0 tool" && return

tool=$1
echo "[INFO] Check dependent tool -- $tool"
ztool=`which $tool 2>/dev/null`
[ "$ztool" = "" ] && echo "[ERROR] $tool environment is failed" && return 1
return 0
}

function func_bld_android() {
echo "[INFO] func_bld_android"
cd $ROOT/prebuild-checking
#sh build_android_check.sh || errstr="$errstr\n[ERR] happen in bld_android"
#libfiles=(`ls ../vendor/mari/build/android/Release/libs/armeabi-v7a/*.a 2>/dev/null`)
#if [ -z "$libfiles" ]; then
#    errstr="$errstr\n[ERR] cannot find the library of bld_android!"
#fi

rm -fr ../unittest/bld/android/bin
sh build_android_app_check.sh || errstr="$errstr\n[ERR] happen in bld_android_app"
libfiles=(`ls ../unittest/bld/android/bin/*.apk 2>/dev/null`)
if [ -z "$libfiles" ]; then
errstr="$errstr\n[ERR] cannot find the apk of bld_android_app!"
fi
cd $ROOT
git checkout .
}

function func_bld_ios() {
echo "[INFO] func_bld_ios"
#unlock the keychain
security unlock-keychain -p p@ss123 /Users/jenkins/Library/Keychains/login.keychain || echo fail
security unlock-keychain -p pass /Users/jenkins/Library/Keychains/login.keychain || echo fail
security unlock-keychain -p wme@cisco /Users/jenkins/Library/Keychains/login.keychain || echo fail

cd $ROOT/prebuild-checking
#sh build_ios_check.sh || errstr="$errstr\n[ERR] happen in bld_ios"
sed -i "" 's/exitOnFailure xcodebuild/exitOnFailure xcodebuild CODE_SIGN_IDENTITY="iPhone Developer: wme-jenkins gen (C26SFX6SSR)"/' ./build_ios_app_check.sh
sh build_ios_app_check.sh || errstr="$errstr\n[ERR] failed when build ios app"
}

function func_bld_mac() {
echo "[INFO] func_bld_mac"
cd $ROOT/prebuild-checking
sh build_mac_check.sh || errstr="$errstr\n[ERR] happen in bld_mac"

nasm_version=`nasm -v | awk -F" " '{printf $3}'`
if [ "${nasm_version}" = "2.11.08" ]; then
errstr="$errstr\n[ERR] nasm version should not be 2.11.08"
fi

#check the jenkins push ssh key
#output=`git fetch -n ssh://wme-jenkins1.gen@wme-jenkins.cisco.com:2022/wme-jenkins tag test 2>&1 | grep "Permission denied"`
#[ "${output}x" != "x" ] && errstr="$errstr\n[ERR] jenkins push ssh key verification is failed"
}

function func_ut_android() {
echo "[INFO] func_ut_android"
cd $ROOT/prebuild-checking
sh ut_android_check.sh || errstr="$errstr\n[ERR] happen in ut_android"
xmlfiles=(`ls ../build/android/report/release/*.xml 2>/dev/null`)
if [ -z "$xmlfiles" ]; then
errstr="$errstr\n[ERR] cannot find the ut_android xml!"
fi
for file in ${xmlfiles[*]}; do
parse_xml $file
if [ $? -ne 0 ]; then
errstr="$errstr\n[ERR] case failed in ut_android xml!"
fi
done

}

function func_ut_ios() {
echo "[INFO] func_ut_ios"

cd $ROOT/prebuild-checking
tar -xzf bin.tar.gz
sh ut_ios_check.sh || errstr="$errstr\n[ERR] happen in ut_ios"
xmlfiles=(`ls ./report/ut_ios/*.xml 2>/dev/null`)
if [ -z "$xmlfiles" ]; then
errstr="$errstr\n[ERR] cannot find the ut_ios xml!"
fi
for file in ${xmlfiles[*]}; do
parse_xml $file
if [ $? -ne 0 ]; then
errstr="$errstr\n[ERR] case failed in ut_ios xml!"
fi
done
}

function func_ut_mac() {
echo "[INFO] func_ut_mac"
cd $ROOT/prebuild-checking
sh ut_mac_check.sh || errstr="$errstr\n[ERR] happen in ut_mac"
xmlfiles=(`ls ./report/ut_mac/*.xml 2>/dev/null`)
if [ -z "$xmlfiles" ]; then
errstr="$errstr\n[ERR] cannot find the ut_mac xml!"
fi
for file in ${xmlfiles[*]}; do
parse_xml $file
if [ $? -ne 0 ]; then
errstr="$errstr\n[ERR] case failed in ut_mac xml!"
fi
done
}

function func_ta_mac() {
echo "[INFO] func_ta_mac"

export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

source ~/.bash_profile

cd $ROOT/ta/ref-app/iOS/build
tar -xzf Release-iphoneos.tar.gz
cd $ROOT/ta/ref-app/MacOSX/MediaSessionTest/bin
tar -xzf Release.tar.gz
cd $ROOT/ta/ref-app/ta_as_dummy_app/macosx/bin
tar -xzf Release.tar.gz

# ta cases
cd  $ROOT/ta/ref-app

rvm gemset list
rvm gemset use calabash
bundle install
#bundle exec


linus_address=http://${hz_linus_ip}:5000/
echo "$node" | grep "SJC\|master" 2>/dev/null 1>&2 && linus_address=http://${sjc_linus_ip}:5000/
UT_APP_ID="com.cisco.MediaSessionIntegrationTest"
GREP_RESULT=`system_profiler SPUSBDataType | sed -n -e '/iPad/,/Serial/p' -e '/iPhone/,/Serial/p' | grep "Serial Number:" | awk -F ": " '{print $2}'`

for DEVICE_ID in ${GREP_RESULT}
do
echo "Try to uninstall the ta-app on device:${DEVICE_ID}"
INSTALL_APP=`$ROOT/prebuild-checking/tools/iFileTransfer -o list -id ${DEVICE_ID} 2>&1 | grep ${UT_APP_ID}`
if [ "${INSTALL_APP}x" != "x" ]; then
echo "uninstall the application: ${UT_APP_ID}"
#uninstall the application from device to remove the last result
$ROOT/prebuild-checking/tools/fruitstrap uninstall --bundle ${UT_APP_ID} --id ${DEVICE_ID}
if [ $? != 0 ]; then
errstr="$errstr\n[ERR] uninstall application: ${UT_APP_ID} from device: ${DEVICE_ID} is failed!"
fi
fi
done

cucumber ta_features --tags @gc-activespeaker --format pretty --format json --out report.json --format rerun --out rerun.txt --format junit --out junit LINUS_SERVER="${linus_address}"

xmlfiles=(`ls ./junit/*.xml 2>/dev/null`)
if [ -z "$xmlfiles" ]; then
errstr="$errstr\n[ERR] cannot find the ta_mac xml!"
fi
for file in ${xmlfiles[*]}; do
parse_xml $file
if [ $? -ne 0 ]; then
errstr="$errstr\n[ERR] case failed in ta_mac xml!"
fi
done
}


###################################################

function func_bld_win() {
echo "[INFO] func_bld_win"
cd $ROOT/prebuild-checking
cmd /c call build_win_check.bat || errstr="$errstr\n[ERR] happen in bld_win"

#check the jenkins push ssh key
#    output=`git fetch -n ssh://wme-jenkins1.gen@wme-jenkins.cisco.com:2022/wme-jenkins tag test 2>&1 | grep "Permission denied"`
#    [ "${output}x" != "x" ] && errstr="$errstr\n[ERR] jenkins push ssh key verification is failed"
}

function func_bld_wp8() {
echo "[INFO] func_bld_wp8"
cd $ROOT/prebuild-checking
cmd /c call build_wp8_check.bat || errstr="$errstr\n[ERR] happen in bld_wp8"
cd $ROOT/ta/ref-app/WP8/buildscript
cmd /c call python refapp_build_wp8.py clean || errstr="$errstr\n[ERR] happen in bld_wp8_ref"
}

function func_ut_win() {
echo "[INFO] func_ut_win"

cd $ROOT/prebuild-checking
cmd /c call ut_win_check.bat || errstr="$errstr\n[ERR] happen in ut_win"
xmlfiles=(`ls ../mediaengine/bin/Win32/Release/*.xml 2>/dev/null`)
if [ -z "$xmlfiles" ]; then
errstr="$errstr\n[ERR] cannot find the ut_win xml!"
fi
for file in ${xmlfiles[*]}; do
parse_xml $file
if [ $? -ne 0 ]; then
errstr="$errstr\n[ERR] case failed in ut_win xml!"
fi
done
}

function func_ut_wp8() {
echo "[INFO] func_ut_wp8"

cd $ROOT/prebuild-checking
cmd /c call ut_wp8_check.bat || errstr="$errstr\n[ERR] happen in ut_wp8"
xmlfiles=(`ls ./XML_Release_DolphinTestApp/*.xml 2>/dev/null`)
if [ -z "$xmlfiles" ]; then
errstr="$errstr\n[ERR] cannot find the ut_wp8 xml!"
fi
for file in ${xmlfiles[*]}; do
parse_xml $file
if [ $? -ne 0 ]; then
errstr="$errstr\n[ERR] case failed in ut_wp8 xml!"
fi
done
}

function func_ta_win() {
echo "[INFO] func_ta_win"

export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# ta cases
cd  $ROOT/ta/ref-app

linus_address=http://${hz_linus_ip}:5000/
echo "$node" | grep "SJC\|master" 2>/dev/null 1>&2 && linus_address=http://${sjc_linus_ip}:5000/
cmd /c call cucumber ta_features --tags @android-filecapture --format pretty --format json --out report.json --format rerun --out rerun.txt --format junit --out junit LINUS_SERVER="${linus_address}"

xmlfiles=(`ls ./junit/*.xml 2>/dev/null`)
if [ -z "$xmlfiles" ]; then
errstr="$errstr\n[ERR] cannot find the ta_win xml!"
fi
for file in ${xmlfiles[*]}; do
parse_xml $file
if [ $? -ne 0 ]; then
errstr="$errstr\n[ERR] case failed in ta_win xml!"
fi
done
}







###################################################
## Main Entry
###################################################

## For mac
echo "$jobs" | grep "bld_android" >/dev/null 2>&1 && func_bld_android
echo "$jobs" | grep "bld_ios"     >/dev/null 2>&1 && func_bld_ios
echo "$jobs" | grep "bld_mac"     >/dev/null 2>&1 && func_bld_mac
echo "$jobs" | grep "ut_android"  >/dev/null 2>&1 && func_ut_android
echo "$jobs" | grep "ut_ios"      >/dev/null 2>&1 && func_ut_ios
echo "$jobs" | grep "ut_mac"      >/dev/null 2>&1 && func_ut_mac
echo "$jobs" | grep "ta_mac"      >/dev/null 2>&1 && func_ta_mac


## For win
echo "$jobs" | grep "bld_win"     >/dev/null 2>&1 && func_bld_win
echo "$jobs" | grep "bld_wp8"     >/dev/null 2>&1 && func_bld_wp8
echo "$jobs" | grep "ut_win"      >/dev/null 2>&1 && func_ut_win
echo "$jobs" | grep "ut_wp8"      >/dev/null 2>&1 && func_ut_wp8
echo "$jobs" | grep "ta_win"      >/dev/null 2>&1 && func_ta_win

echo
echo
echo "********************Summary info***********************"
echo
if [ "$errstr" != "" ]; then

echo -e $errstr
echo
echo "*****************************************************"
exit 1
fi
echo "pre-build health checking is successful!!!"
echo
echo "*****************************************************"
exit 0