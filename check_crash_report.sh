#!/usr/bash

#Remove the former crash reports
mkdir -p ~/Library/Logs/DiagnosticReports/
mkdir -p ~/Library/Logs/DiagnosticReports-bak/
mv ~/Library/Logs/DiagnosticReports/*.crash ~/Library/Logs/DiagnosticReports-bak/
#rm -fr *.crash

#Do testing


#Check the new crash reports
cd ~/Library/Logs/DiagnosticReports
crashReport=(`ls ./*.crash 2>/dev/null`)
if [ !  -z "$crashReport" ]; then
echo "the crash report is exist"
fi
echo $crashReport
echo "end"