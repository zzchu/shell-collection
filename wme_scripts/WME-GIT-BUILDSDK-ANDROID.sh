set -e
set +x
source ~/.bash_profile
wmepath=$WORKSPACE/$repo_loc/$wme_loc

#echo START TO CLEAN PREVIOUS GENERATED DISTRIBUTION
#echo "[*] to clean old libs"
#libspath=$wmepath/distribution/android/armv7
#[ -d "$libspath" ] && rm -rf $libspath/*

echo START TO BUILD SDK
cd $wmepath/build/android/
git branch -a

if [ "$fast_mode" = "yes" ]; then

echo "[*] enable the fast mode"
cd $wmepath/build/android/
python build.py release
err=$?
[ $err -ne 0 ] && exit 1

echo "[*] to archive libs"
cd $wmepath/distribution/android/armv7
mkdir debug
rm -rf android*.tar.gz maps*.tar.gz
[ -d maps ] && tar -czf maps-release.tar.gz maps
[ -d release ] && tar -czf android-release.tar.gz release
[ -d maps ] && mv maps maps-release

else

profiles="debug release"
echo "[*] to build $profiles"

cd $wmepath/build/android/
logf="log-build-$(date +%s)"
git checkout buildtool.py
sed -i "" 's/ndk-build/ndk-build -j4/' buildtool.py

for profile in $profiles;
do
[ "$profile" = "release" ] && sleep 90
[ "$profile" = "debug" ] && echo $profile "/dev/stdout" || echo $profile "$logf-$profile.txt"
done | xargs -P 2 -I "{}" bash -c '{  argv=({}); echo "[*] to build ${argv[0]}" >${argv[1]}; python build.py ${argv[0]} >>${argv[1]} 2>&1; }'
err=$?
git checkout buildtool.py

#cat $logf-debug.txt
echo
cat $logf-release.txt
[ $err -ne 0 ] && exit 1


echo "[*] to package libs"
for profile in $profiles;
do
cd $wmepath/build/android/ && python build.py $profile >/dev/null 2>&1
cd $wmepath/distribution/android/armv7
rm -rf android*.tar.gz maps*.tar.gz
[ -d maps ] && tar -czf maps-${profile}.tar.gz maps
[ -d "$profile" ] && tar -czf android-${profile}.tar.gz $profile
[ -d maps ] && mv maps maps-$profile
done

fi

#######################

set -e
set +x
source ~/.bash_profile
wmepath=$WORKSPACE/$repo_loc/$wme_loc

echo START TO PACKAGE SDK
echo "[*] to package libs"
cd $wmepath/build/android/
rm -rf MediaSDK_Demo_Android.tar.gz
sh package.sh

echo "[*] to package libs for train"
cd $wmepath/build/android/
rm -rf wme4train_android.tar.gz
python package4train.py

cd $wmepath/
rm -rf INFO-Android-Package*
touch INFO-Android-Package-p${parent_build_number}-s${BUILD_NUMBER}-${git_commit_revision}

exit 0

##################
set -e
set +x
source ~/.bash_profile
wx2testpath=$WORKSPACE/$repo_loc/$wme_loc/ta
#Clean last build archive
cd $wx2testpath

echo START TO BUILD REF-APP
echo "build android test app"
cd $wx2testpath/ref-app/android
python build.py clean
python build.py release

cd $wx2testpath/ref-app/android/ClickCall
[ -d target ] && tar -czf android-ta-target.tar.gz target
exit 0