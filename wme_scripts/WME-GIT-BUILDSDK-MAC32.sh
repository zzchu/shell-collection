source ~/.bash_profile
wmepath=$WORKSPACE/$repo_loc/$wme_loc

echo "[*] to clean old libs"
macdist=$wmepath/distribution/mac/
[ -d "$macdist" ] && rm -rf $macdist/*


echo "[*] to build wme mac32"
err=0
cd $wmepath/build/mac/
git branch -a
sh build.sh -a 32
#sh build_refapp.sh
err=$?
exit $err


################################
source ~/.bash_profile
wmepath=$WORKSPACE/$repo_loc/$wme_loc


echo "[*] to package libs"

rm -rf $wmepath/distribution/mac/mac-*.tar.gz

cd $wmepath/build/mac
rm -rf MediaSDK*.tar.gz
sh package.sh
python package4train.py

cd $wmepath/distribution/mac
mkdir -p {Debug,Release}
tar -czf mac-debug.tar.gz Debug
tar -czf mac-release.tar.gz Release

cd $wmepath/
rm -rf INFO-Mac-Package*
touch INFO-Mac-Package-${parent_build_number}-j${BUILD_NUMBER}-${git_commit_revision}

exit 0