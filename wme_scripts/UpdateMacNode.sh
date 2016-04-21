#!/bin/bash --login
ROOT=$WORKSPACE/$repo_loc/$env_update_loc
cd $ROOT

security unlock-keychain -p wme@cisco /Users/jenkins/Library/Keychains/login.keychain
security unlock-keychain -p p@ss123 /Users/jenkins/Library/Keychains/login.keychain

#update the iOS development certificate & provision profile
./scripts/developer_tools.rb $DEV_CERT_PASSWORD 'iPhone Developer: wme-jenkins gen (26CW9V38S8)' "./wme-jenking.gen-cert-jenkins-use-only.p12" "./WMEJenkinsgen_spark_profile.mobileprovision" "3905ba37-d231-4e39-8fd8-f410d79346df"

./scripts/developer_tools.rb $DEV_CERT_PASSWORD 'iPhone Developer: wme-jenkins gen (26CW9V38S8)' "./wme-jenking.gen-cert-jenkins-use-only.p12" "./WMEJenkinsgen_profile.mobileprovision" "709f5de6-d5b5-461b-955a-f23f4e6bee4f"

#unify the android ndk version
ndkfolder="$HOME/Downloads/android-ndk-r10e"

if [ ! -d "$ndkfolder" ]; then
echo "start to download the android NDK!"
cd $HOME/Downloads
curl -k -s -S -O https://dl.google.com/android/ndk/android-ndk-r10e-darwin-x86_64.bin
chmod a+x android-ndk-r10e-darwin-x86_64.bin
./android-ndk-r10e-darwin-x86_64.bin
fi

ndksymbol="$HOME/Downloads/android-ndk"
rm -rf $ndksymbol
ln -s $ndkfolder $ndksymbol

sed -i "" 's#ANDROID_NDK_HOME=.*#ANDROID_NDK_HOME=$HOME/Downloads/android-ndk#' $HOME/.bash_profile
sed -i "" 's#ANDROID_NDK_HOME=.*#ANDROID_NDK_HOME=$HOME/Downloads/android-ndk#' $HOME/.profile
echo "set android NDK environment variable completely!"

if [ ! -d "$myPath"]; then
mkdir "$myPath"
fi

echo "android home:$ANDROID_HOME"
androidSDKfolder="$ANDROID_HOME/platforms/android-22"
rm -fr $ANDROID_HOME/platforms/*.zip
if [ ! -d "$androidSDKfolder" ]; then
cd $ANDROID_HOME/platforms
cp -fr $ROOT/tools/android-22.zip .
tar -xzf android-22.zip
rm -fr android-22.zip
echo "install android-22 completely!!"
fi

echo "unify the RVM version"
rvm get stable

exit 0

#################

#!/bin/bash --login +x
source ~/.bash_profile
set +x
set +e
pkg=""
sudo=""


function check_env() {
echo "[INFO] Check env /usr/local/bin"
if [[ "$PATH" =~ "/usr/local/bin" ]]; then
echo "[OK] /usr/local/bin exists in PATH"
else
echo "[WARN] Add /usr/local/bin in PATH"
echo "export PATH=/usr/local/bin:\$PATH" >> ~/.bash_profile
export PATH=/usr/local/bin:$PATH
fi
sudo -A ls 2>/dev/null && sudo="sudo -A" || sudo=""
}

function check_pkg() {
pkg=`which brew 2>/dev/null`
[ "$pkg" = "" ] && echo "[ERROR] no tools - brew (default)" && exit 1
echo "[OK] find tool: $pkg"
}

function check_tool() {
[ $# -ne 1 ] && echo "[WARN] $0 tool" && return

tool=$1
echo "[INFO] Check and install dependent tool -- $tool"
ztool=`which $tool 2>/dev/null` || return
$ztool -version 2>/dev/null || $ztool --version 2>/dev/null

if [ "$action" = "install" ]; then
if [ "$ztool" = "" ]; then
$sudo $pkg install $tool
ztool=`which $tool 2>/dev/null`
[ "$ztool" = "" ] && echo "[ERROR] cannot install $tool" && return
fi
echo "[OK] Installed: ${ztool}"
fi
}

function check_Android() {
[ "$ANDROID_HOME" = "" ] && echo "[ERROR] no android sdk" && return
[ "$ANDROID_NDK_HOME" = "" ] && echo "[ERROR] no android ndk" && return

echo "[INFO] android sdk: $ANDROID_HOME"
echo "[INFO] android ndk: $ANDROID_NDK_HOME"
if [[ "$PATH" =~ "/platform-tools" ]]; then
echo "[INFO] sdk tools: $ANDROID_HOME/platform-tools"
else
echo "export PATH=\$ANDROID_HOME/platform-tools:\$PATH" >> ~/.bash_profile
export PATH=$ANDROID_HOME/platform-tools:$PATH
fi

if [ "$ANDROID_NDK" = "" ]; then
echo "export ANDROID_NDK=\$ANDROID_NDK_HOME" >> ~/.bash_profile
fi
}

function check_adev() {
echo "[INFO] check android devices"
adb=$(which adb 2>/dev/null)
[ "$adb" = "" ] && return

devices=(`$adb devices | awk -F" " '/\tdevice/{print $1}'`)
devnum=${#devices[*]}
for dev in ${devices[*]}; do
state=`$adb -s $dev get-state`
[ "$state" != "device" ] && devnum=$((devnum-1)) && echo "[WARN] The status of $dev is not normal"
done

realnum=0
[ $NODE_NAME = "master" ] && realnum=2
[ $NODE_NAME = "IMAC-SJC" ] && realnum=1
[ $NODE_NAME = "MAC-MINI-COMM1" ] && realnum=2
[ $NODE_NAME = "MACMINI-HZ-01" ] && realnum=1

[ $devnum -lt $realnum ] && echo "[WARN] some android devices are unavailable in <$NODE_NAME>"
}

function check_nasm() {
echo "[INFO] check nasm ..."
if [ -f /usr/local/bin/nasm ]; then
$sudo cp -f /usr/local/bin/nasm /usr/bin/nasm 2>/dev/null
else
$sudo rm -f /usr/bin/nasm
#check_tool nasm
brew install nasm
brew switch nasm 2.11.06
$sudo cp -f /usr/local/bin/nasm /usr/bin/nasm || return
fi
nasm -version
}

function check_brew() {
echo "[INFO] check brew"
build=$(which brew 2>/dev/null)
if [ "$build" = "" ]; then
echo "[WARN] No brew installed"
if [ "$action" = "install" ]; then
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
return
fi
else
echo "[OK] brew version"
$build --version
fi
}

function check_Xcode() {
echo "[INFO] check Xcode tools"
build=$(which xcodebuild 2>/dev/null)
if [ "$build" = "" ]; then
echo "[WARN] No Xcode installed" && return
else
echo "[OK] xcodebuild version"
$build -version
fi

echo
echo "[INFO] check iOS devices"
which ios-deploy 2>/dev/null && deploy=ios-deploy
if [ "$deploy" = "" ]; then
echo "[WARN] no ios-deploy installed"
if [ "$action" = "install" ]; then
brew install node
npm install -g ios-deploy
else
return
fi
else
echo "[OK] have iOS devices: "
$deploy -c
fi
}

#ios client build suggests to use xctool
function check_xctool() {
echo "[INFO] check xctool"
build=$(which xctool 2>/dev/null)
if [ "$build" = "" ]; then
echo "[WARN] No xctool installed"
if [ "$action" = "install" ]; then
brew install xctool
else
return
fi
else
echo "[OK] xctool version"
$build -version
fi
}

function check_calabash() {
echo "[INFO] checking calabash..."
gem=$(which gem 2>/dev/null)
[ "$gem" = "" ] && echo "[ERROR] no tools - gem" && return

echo "[OK] check and install calabash iOS and android"
rvm=$(which rvm 2>/dev/null)
$rvm use default
$rvm gemset use calabash
which calabash-ios
which calabash-android

if [ "$action" = "install" ]; then
which calabash-ios 2>/dev/null 1>&2 || $sudo $gem install calabash-cucumber
which calabash-android 2>/dev/null 1>&2 || $sudo $gem install calabash-android
fi
}

function check_Ruby() {
echo "[INFO] check Ruby tools"
ruby=$(which ruby 2>/dev/null)
if [ "$ruby" = "" ]; then
echo "[WARN] No Ruby installed" && return
else
echo "[OK] ruby version: "
$ruby --version
fi

echo
echo "[INFO] check rvm tools"
rvm=$(which rvm 2>/dev/null)
if [ "$rvm" = "" ]; then
echo "[WARN] No rvm installed" && return
else
echo "[OK] rvm version:"
$rvm version
fi

if [ "$action" = "install" ]; then
echo
echo "[INFO] set ruby default as 2.1.2"
gem=$(which gem 2>/dev/null)
ruby_version=`$ruby --version|awk '{print $2}'`
if [[ "$ruby_version" =~ "2.1.2" ]]; then
echo "[OK] default ruby is $ruby_version"
else
echo "[INFO] default ruby version is $ruby_version; set 2.1.2 as default"
$rvm list|grep 2.1.2 2>/dev/null 1>&2 || rvm install 2.1.2 2>/dev/null
$rvm --default --create use 2.1.2 2>/dev/null 1>&2
fi
$rvm gemset create calabash
$rvm gemset use calabash
$gem install cucumber -v 1.3.18
cucumber_loc=`$gem which cucumber`
cp $WORKSPACE/wme-jenkins/scripts/{junit,rerun}.rb "$(dirname $cucumber_loc)/cucumber/formatter"
fi
}





#echo && check_env
#echo && check_pkg
#echo && check_Ruby
#echo && check_calabash
#echo && check_brew
#echo && check_tool cmake
#echo && check_tool ant
#echo && check_Android
#echo && check_Xcode
#echo && check_xctool
#echo && check_nasm



exit 0