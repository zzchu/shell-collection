#!/usr/bash
string="one,two,three"
OLD_IFS="$IFS"
IFS=","
array=($string)
IFS="$OLD_IFS"
for s in ${array[@]}
do
echo "$s"
done