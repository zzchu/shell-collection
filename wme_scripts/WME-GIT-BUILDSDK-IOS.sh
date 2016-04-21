#!/bin/bash --login
set +x
source ~/.bash_profile
wmepath=$WORKSPACE/$repo_loc/$wme_loc

#echo START TO CLEAN PREVIOUS GENERATED DISTRIBUTION
#echo "[*] to clean old libs"
#libspath=$wmepath/distribution/ios
#[ -d "$libspath" ] && rm -rf $libspath/*

echo START TO BUILD SDK
echo "[*] to build wme ios"
cd $wmepath/build/ios/
git branch -a
echo "ready to build with fast mode: $fast_mode"
if [ "$fast_mode" = "no" ]; then
    sh build.sh
    err=$?
else
    sed -i "" "s/armv7 armv7s arm64/$fast_mode_iOS_ARCH/" ./build.sh
    sed -i "" "s/armv7 arm64/$fast_mode_iOS_ARCH/" ./build.sh
    sh build.sh dev release
    err=$?
    git checkout build.sh
fi

exit $err


###################################
#!/bin/bash --login
source ~/.bash_profile
wmepath=$WORKSPACE/$repo_loc/$wme_loc

echo START TO PACKAGE SDK
echo "[*] to package wme ios distribution"
cd $wmepath/build/ios
rm -f *.tar.gz
sh package.sh

    cd $wmepath/distribution/ios/
    mkdir -p release
    cp -rf Release-* release
    tar -czf ios-release.tar.gz release

if [ "$fast_mode" = "no" ]; then
    mkdir -p debug
    cp -rf Debug-* debug 
    tar -czf ios-debug.tar.gz debug
fi

cd $wmepath/
rm -rf INFO-IOS-Package*
touch INFO-IOS-Package-p${parent_build_number}-s${BUILD_NUMBER}-${git_commit_revision}

exit 0

####################################
#!/bin/bash --login
source ~/.bash_profile
wx2testpath=$WORKSPACE/$repo_loc/$wme_loc/ta
cd $wx2testpath

echo START TO BUILD REF-APP
echo "build ios test app"
cd $wx2testpath/ref-app/iOS/script
date; security unlock-keychain -p p@ss123 /Users/jenkins/Library/Keychains/login.keychain || echo fail
security unlock-keychain -p pass /Users/jenkins/Library/Keychains/login.keychain || echo fail
security unlock-keychain -p wme@cisco /Users/jenkins/Library/Keychains/login.keychain || echo fail
sed -i "" 's/exitOnFailure xcodebuild/exitOnFailure xcodebuild CODE_SIGN_IDENTITY="iPhone Developer: wme-jenkins gen (C26SFX6SSR)"/' ./build.sh
sed -i "" 's/ONLY_ACTIVE_ARCH=NO ${PROJECT_CLEAN}/ONLY_ACTIVE_ARCH=NO IPHONEOS_DEPLOYMENT_TARGET=7.1 ENABLE_BITCODE=NO  ${PROJECT_CLEAN}/' ./build.sh

if [ "$fast_mode" = "yes" ]; then
    sed -i "" "s/armv7 arm64/$fast_mode_iOS_ARCH/" ./build.sh
fi
sh build.sh
err=$?
git checkout build.sh
cd ../build
rm -f ios-ta-app.tar.gz
[ -d Release-iphoneos ] && tar -czf ios-ta-app.tar.gz Release-iphoneos


cd $wx2testpath/ref-app
tar -czf ta_features.tar.gz ta_features
cp ta_features.tar.gz $wx2testpath/


exit $err



