#!/bin/bash --login
source ~/.bash_profile
cd $WORKSPACE/wme-jenkins/scripts
gem=$(which gem 2>/dev/null)
echo "[INFO] prepare env"
rvm=$(which rvm 2>/dev/null)
$rvm use default
rvm gemset use calabash
$gem install bundle
bundle install

brew=$(which brew 2>/dev/null)
libplist=`$brew list|grep libplist 2>/dev/null`
if [ "$libplist" = "" ]; then
$brew install libplist
fi
libimobiledevice=`$brew list|grep libimobiledevice 2>/dev/null`
if [ "$libimobiledevice" = "" ]; then
$brew install libimobiledevice
fi

idevice_loc=`$gem which idevice`
plist_file="$(dirname $idevice_loc)/idevice/plist.rb"
commented=$(sed -n '319p' $plist_file|sed -e 's/^[ \t]*//'|grep "^#")
if [ "$commented" = "" ];then
sed -i '' '319 s/^/#/' $plist_file
fi

echo "[INFO] Restarting..."
osascript repair_instruments_applescript.scpt
killall instruments
chmod +x restart-devices.py
./restart-devices.py
res=$?
echo $res
exit $res

