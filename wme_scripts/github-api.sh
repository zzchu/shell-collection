set +e
if [ $ghprbTargetBranch == "master" ];then
echo "[ERROR] you push code to a wrong remote target; EXIT"
curl -i https://sqbu-github.cisco.com/api/v3/repos/WebExSquared/wme/issues/$ghprbPullId/comments -u "wme-jenkins-gen:$gen_pass" -X POST -d "{\"body\": \"Test FAILed- \nyou push code to a wrong remote target!!!\"}"
exit 1
fi

git remote|grep jenkins-pr-branch
[ $? -eq 1 ] && git remote add jenkins-pr-branch ssh://wme-jenkins.gen@wme-jenkins.cisco.com:2022/Pipeline-PullRequest-Branch

echo "build ${BUILD_NUMBER}"
git rev-parse HEAD
git reset --merge
git checkout -b pr#${BUILD_NUMBER}
git rev-parse HEAD
git fetch
git checkout $ghprbTargetBranch
git reset --hard origin/$ghprbTargetBranch

#add the rebase process
#git checkout pr#${BUILD_NUMBER}
#git rebase $ghprbTargetBranch
#git checkout $ghprbTargetBranch

git merge pr#${BUILD_NUMBER}

if [ $? -eq 0 ]; then
git push jenkins-pr-branch $ghprbTargetBranch
else
curl -i https://sqbu-github.cisco.com/api/v3/repos/WebExSquared/wme/issues/$ghprbPullId/comments -u "wme-jenkins-gen:$gen_pass" -X POST -d "{\"body\": \"Test FAILed- \nMerge conflict and abort test!!!\"}"
exit 1
fi