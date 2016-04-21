#!/bin/bash
source ~/.bash_profile
set -e
set +x

#support the ut module is null
[ "$ios_ut_modules" = "" ] && exit 0

wmepath=$WORKSPACE/$repo_loc/$wme_loc
cd $wmepath
git clean -dfx
git checkout build/ios/build_ut.sh
echo START TO GET SDK PACKAGES
mkdir -p $wmepath/distribution/ios
rm -rf $wmepath/distribution/ios/*


cd $wmepath/distribution/ios/
[ "$bld_ios_url" = "" ] && bld_ios_url="$UPSTREAM_URL"
UPSTREAM_BASE=${bld_ios_url}/artifact/$repo_loc/$wme_loc/distribution/ios/
date
curl -C - --retry 3 --retry-delay 60 -k -s -S -O -u wme-jenkins1.gen:d67f0ebb7ab2d9f33c1f96ae64c30f61 ${UPSTREAM_BASE}ios-release.tar.gz
#curl -C - --retry 3 --retry-delay 60 -k -s -S -O ${UPSTREAM_BASE}ios-debug.tar.gz
date

tar -xzf ios-release.tar.gz
[ -d release ] && cp -r release/* .
rm -rf release ios-release.tar.gz

#tar -xzf ios-debug.tar.gz
#[ -d debug ] && cp -r debug/* .
#rm -rf debug ios-debug.tar.gz

##############################

#!/bin/bash
source ~/.bash_profile
set +e
set +x
export LC_CTYPE=en_US.UTF-8

#support the ut module is null
[ "$ios_ut_modules" = "" ] && exit 0

wmepath=$WORKSPACE/$repo_loc/$wme_loc
date; security unlock-keychain -p ${KEYCHAIN_PWORD} /Users/jenkins/Library/Keychains/login.keychain || echo fail
security unlock-keychain -p pass /Users/jenkins/Library/Keychains/login.keychain || echo fail
security unlock-keychain -p wme@cisco /Users/jenkins/Library/Keychains/login.keychain || echo fail

echo START TO BUILD AND RUN UT APP
echo "Running UT on device"
cd $wmepath/build/ios
rm -rf report/release/*

#specify the developer certification
sed -i "" 's/xcodebuild ARCHS="${WME_UNITTEST_IOS_ARCH}"/xcodebuild ARCHS="${WME_UNITTEST_IOS_ARCH}" CODE_SIGN_IDENTITY="iPhone Developer: wme-jenkins gen (C26SFX6SSR)"/' ./build_ut.sh
sed -i "" 's/"armv7 arm64"/"arm64"/' ./build_ut.sh
#FIXME- after all of library have the bitcode
sed -i "" 's/ONLY_ACTIVE_ARCH=NO -project/ONLY_ACTIVE_ARCH=NO IPHONEOS_DEPLOYMENT_TARGET=7.1 ENABLE_BITCODE=NO -project/' ./build_ut.sh

if [[ "$ios_ut_modules" =~ "all" ]]; then
sh build_ut.sh dev release
else
OLD_IFS="$IFS" && IFS="," && ut_modules=($ios_ut_modules) && IFS="$OLD_IFS"
for mod in ${ut_modules[@]}; do
echo "[*]Build and Run $mod UT modules"
sh build_ut.sh dev release "" $mod
done
fi

############################
source ~/.bash_profile
set +e
set +x
wmepath=$WORKSPACE/$repo_loc/$wme_loc

#support the ut module is null
[ "$ios_ut_modules" = "" ] && exit 0

echo "generate instruments traces ..."
cd $wmepath/build/ios/
mkdir -p instrumentscli0.trace
tar -czf instruments_trace.tar.gz instrumentscli*.trace


cd $wmepath/
rm -rf INFO-UT-IOS*
touch INFO-UT-IOS-h${parent_build_number}-j${BUILD_NUMBER}-${git_commit_revision}
mkdir -p $WORKSPACE/generatedJUnitFiles/GoogleTest/

echo "generate artifaces"
cd $WORKSPACE/$repo_loc/$wme_loc/build/ios/report
tar -czf ios_release_ut_report.tar.gz release/*.xml
tar -czf ios_release_ut_wbt.tar.gz release/wbxlogs
[ -d "release/Crashes" ] && tar -czf ios_release_ut_crashes.tar.gz release/Crashes

exit 0