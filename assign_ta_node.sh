#!/usr/bash

ta_nodes="node0"
target_file=~/Desktop/demo_tag_config.txt
output_file=~/Desktop/output_tag_config.txt



#divide the node expression by ","
i=0
for nodeExpr in `echo $ta_nodes | sed 's/,/ /g'`
do
nodeExprArry[$i]=$nodeExpr
i=`expr $i + 1`
done

arryLen=${#nodeExprArry[*]}

echo slaves:${nodeExprArry[*]}


j=0
loopback=0

>$output_file

while read line || [ -n "$line" ]
do

result=`echo ${line} | grep 'mac\s\+=\|mac='`
if [ "${result}x" = x ]; then
continue
fi


for node_name in `echo ${nodeExprArry[$j]} | sed 's/||/ /g'`
do
#node_name=${nodeExprArry[$j]}
if [ $loopback -eq 0 ]; then
echo ${line} | awk -F"=" -v n=$node_name '{printf "%s=%s\n",n,$2}' >> ${output_file}
else
appendTags=`echo ${line} | awk -F"=" '{print $2}'`
sed -i "" "s/$node_name"="\(.*\)/$node_name"="\1,$appendTags/" $output_file
fi
done

j=`expr $j + 1`
if [ $j -ge $arryLen ]; then
j=0
loopback=1
fi

done < ${target_file}
