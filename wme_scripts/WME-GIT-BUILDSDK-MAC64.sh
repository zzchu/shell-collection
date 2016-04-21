#!/bin/bash  --login
source ~/.bash_profile
wmepath=$WORKSPACE/$repo_loc/$wme_loc

echo START TO CLEAN ALL PREVIOUS GENERATED DISTRIBUTION
echo "[*] to clean old libs"
macdist=$wmepath/distribution/mac/
[ -d "$macdist" ] && rm -rf $macdist/*

echo START TO BUILD SDK
err=0
echo "[*] to build wme mac64"
cd $wmepath/build/mac/
git branch -a

if [ "$fast_mode" = "no" ]; then
sh build.sh -a 64
else
sh build.sh -a 64 -r
fi
#sh build_refapp.sh
err=$?
exit $err

###########################
#!/bin/bash  --login
source ~/.bash_profile
wmepath=$WORKSPACE/$repo_loc/$wme_loc
err=0
echo START TO PACKAGE SDK
echo "[*] to package libs"

rm -rf $wmepath/distribution/mac/mac-*.tar.gz

cd $wmepath/build/mac
rm -rf MediaSDK*.tar.gz
#sed -i "" '49 s/rf/Rf/' package_64bit.sh
#sed -i "" '50,53 s/^/#/' package_64bit.sh
sh package_64bit.sh
err=$?
cd $wmepath/distribution/mac

if [ "$fast_mode" = "no" ]; then
mkdir -p {Debug,Release}
tar -czf mac-debug.tar.gz Debug
tar -czf mac-release.tar.gz Release
else
mkdir -p Release
tar -czf mac-release.tar.gz Release
fi


cd $wmepath/
rm -rf INFO-Mac-Package*
touch INFO-Mac-Package-${parent_build_number}-j${BUILD_NUMBER}-${git_commit_revision}


exit $err

################################
#!/bin/bash  --login
source ~/.bash_profile
wx2testpath=$WORKSPACE/$repo_loc/$wme_loc/ta
err=0
#Clean last build archive
cd $wx2testpath
echo START TO BUILD REF-APP
echo "build mac test app"
cd $wx2testpath/ref-app/MacOSX/MediaSessionTest/build
sh build_refapp.sh
err=$?
cd $wx2testpath/ref-app/MacOSX/MediaSessionTest/bin
[ -d Release ] && tar -czf mac-ta-app.tar.gz Release
mv mac-ta-app.tar.gz $wx2testpath
cd $wx2testpath/ref-app/ta_as_dummy_app/macosx/bin
[ -d Release ] && tar -czf mac-ta-dummy-app.tar.gz Release
mv mac-ta-dummy-app.tar.gz $wx2testpath

exit $err
