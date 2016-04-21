#!/usr/bash
#find . -name *.gcda -exec rm -f {} \;

TARGET_FILE=~/Desktop/passTarge.txt
REF_FILE=~/Desktop/featureName.txt
RESULT_FILE=~/Desktop/output.txt

SEARCH_DIR=/Users/zzchu/Desktop/git-ws/wme_git/wme/ta/ref-app/ta_features
PREPARE_FILE=/tmp/tmp_prepare.txt
TEMP_FILE1=/tmp/tmp01.txt
TEMP_FILE0=/tmp/tmp00.txt
TEMP_FILE2=/tmp/tmp02.txt
TEMP_FILE3=/tmp/tmp03.txt
TEMP_FILE4=/tmp/tmp04.txt


rm -f ${TEMP_FILE0}
rm -f ${TEMP_FILE1}
rm -f ${TEMP_FILE2}
rm -f ${TEMP_FILE3}
rm -f ${TEMP_FILE4}
rm -f ${TEMP_FILE4}
rm -f ${PREPARE_FILE}

rm -f /tmp/error.txt
#set -x
###################### For preparing the input ###########################

while read line
do
#echo "${line}"
if grep -q "${line}" ${REF_FILE}; then
echo "${line}" #>> /tmp/error.txt
else
#echo "${line}"
echo "${line}" >> ${PREPARE_FILE}
fi
done < ${TARGET_FILE}



###################### For get the related TA tag ########################
awk -F"(" '{print $1}' ${PREPARE_FILE} > ${TEMP_FILE4}
#replace the whitespace with "\s\+"
#set -x
cd ${SEARCH_DIR}
while read line
do
tempstr=`echo ${line} | sed -e 's/ /\\\s\\\+/g'`
#echo ${tempstr}
grep -B 1 "${tempstr}$" . -r >> ${TEMP_FILE0}
grep -B 1 "${tempstr}\s\+$" . -r >> ${TEMP_FILE0}
done < ${TEMP_FILE4}

awk -F"@" '{print "@"$2","}' ${TEMP_FILE0} > ${TEMP_FILE1}

sed -e '/@,/d;s/ //g' ${TEMP_FILE1} > ${TEMP_FILE2}

sort  ${TEMP_FILE2} > ${TEMP_FILE3}
uniq  ${TEMP_FILE3} > ${RESULT_FILE}

exit 0