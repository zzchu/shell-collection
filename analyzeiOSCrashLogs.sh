#!/usr/bash
set +x

echo "###################################################################"
echo "##Checking parameters"

function showUsage()
{
echo "*please use command ==> $0 crash_report dsym_file symbolicated_report"
echo "*crash_report              - specify which crash report will be symbolicated"
echo "*dsym_file                 - specify which dSYM file will be used by symbolication"
echo "*symbolicated_report       - specify the output file for symbolicated crash report"
echo "*for example: sh analyzeiOSCrashLogs.sh "
}

if [ $# -ne 3 ]; then
showUsage
exit 1
fi

cd `pwd`

XCODEDEVELOPER_DIR=`xcode-select --print-path`
XCODECONTENTS_DIR=${XCODEDEVELOPER_DIR}/..

if [ ! -f /usr/bin/symbolicatecrash ]; then
echo "soft link the symbolicatecrash"
sudo ln -s ${XCODECONTENTS_DIR}/SharedFrameworks/DTDeviceKitBase.framework/Versions/A/Resources/symbolicatecrash /usr/bin/symbolicatecrash
fi

export DEVELOPER_DIR=${XCODEDEVELOPER_DIR}

symbolicatecrash -v $1 $2 > $3