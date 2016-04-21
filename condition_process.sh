#!/usr/bash

parent_project="Push"

if [ "$parent_project" = "Push" -o "$parent_project" = "PushBranch" -o "$parent_project" = "PushPR" ]; then

echo "the condition is ok"
else
echo "error!!!!!!!!!!"
fi

exit 0