#!/bin/bash --login +x -e
source ~/.bash_profile

    issue_url=`cat /tmp/git_issue_create.txt | jq '.html_url'|tr -d '"'`
    echo "url: ${issue_url}"
    if [ "${issue_url}" == "null" ]; then
        echo "Try to send the git issue to the comment author!"
    fi
