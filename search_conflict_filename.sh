#!/bin/bash

MAIN_DIR=/Users/zzchu/Desktop/svn-ws/Jenkins/trunk/mediaengine

rm -rf /tmp/wme_conflict
mkdir -p /tmp/wme_conflict

find ${MAIN_DIR} -name "*.cpp" 2>/dev/null -exec basename {} \; >/tmp/wme_conflict/filefullname.txt
find ${MAIN_DIR} -name "*.c" 2>/dev/null -exec basename {} \; >>/tmp/wme_conflict/filefullname.txt
#find ${MAIN_DIR} -iname "*.c*" >/tmp/wme_conflict/filename.txt
while read line
do
echo "${line%.*}" >> /tmp/wme_conflict/filename.txt
done < /tmp/wme_conflict/filefullname.txt


sort  /tmp/wme_conflict/filename.txt > /tmp/wme_conflict/origin.txt
uniq -d /tmp/wme_conflict/origin.txt > /tmp/wme_conflict/result.txt

while read line
do
find ${MAIN_DIR} -name "${line}.c" -o -name "${line}.cpp" >> /tmp/wme_conflict/conflict.txt
done < /tmp/wme_conflict/result.txt

exit 0