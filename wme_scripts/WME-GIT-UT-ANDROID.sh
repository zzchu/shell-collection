source ~/.bash_profile
set -e
wmepath=$WORKSPACE/$repo_loc/$wme_loc

echo START TO GET SDK PACKAGES
mkdir -p $wmepath/distribution/android/armv7
rm -rf $wmepath/distribution/android/armv7/*


cd $wmepath/distribution/android/armv7

[ "$bld_android_url" = "" ] && bld_android_url="$UPSTREAM_URL"
UPSTREAM_BASE=${bld_android_url}/artifact/$repo_loc/$wme_loc/distribution/android/armv7/
curl -C - --retry 3 --retry-delay 60 -k -s -S -O -u wme-jenkins1.gen:d67f0ebb7ab2d9f33c1f96ae64c30f61 ${UPSTREAM_BASE}android-release.tar.gz
sleep 10
curl -C - --retry 3 --retry-delay 60 -k -s -S -O -u wme-jenkins1.gen:d67f0ebb7ab2d9f33c1f96ae64c30f61 ${UPSTREAM_BASE}maps-release.tar.gz

tar xf android-release.tar.gz
#tar xf android-debug.tar.gz
tar xf maps-release.tar.gz
rm -f *.tar.gz

#############

source ~/.bash_profile
set -x
wmepath=$WORKSPACE/$repo_loc/$wme_loc

echo START TO CLEAN PREVIOUS APPS
echo "[*] to clean old unittest app"
utestbld=$wmepath/unittest/bld/android/
rm -rf ${utestbld}/{bin,gen,obj}
rm -rf ${utestbld}/libs/armeabi-v7a/*

echo START TO BUILD UT APP
echo "[*] to build unittest app"
bld_begin=`date +%s`
cd $wmepath/build/android/
git checkout buildtool.py
sed -i "" 's/ndk-build/ndk-build -j2/' buildtool.py
python build_ut.py release pool_num=2
git checkout buildtool.py
bld_end=`date +%s`
echo
echo ================================================================
echo  "[ Total Time for Building UT: $((bld_end-bld_begin)) seconds ]"
echo ================================================================
echo

echo START TO RUN UT
echo "[*] to run unittest app"
adb start-server || true
adb devices || true
cd $wmepath/build/android/
sh run_ut.sh release xreport=-1

#sh run_ut.sh release
devices=(`adb devices | awk -F" " '/\tdevice/{print $1}'`)
devnum=${#devices[*]}
[ $devnum -ge 2 ] && process=2 || process=1
echo "[*] start $process processes to run UT"


if [[ "$android_ut_modules" =~ "all" ]]; then
echo "Run UT: all"
sh run_ut.sh release
else
OLD_IFS="$IFS" && IFS="," && ut_modules=($android_ut_modules) && IFS="$OLD_IFS"
num=${#ut_modules[@]}
#num=$((num/2))
#mods1=${ut_modules[@]:0:num}
#mods2=${ut_modules[@]:num}
echo "Run UT: ${ut_modules[@]}"
sh run_ut.sh release ${ut_modules[@]}
fi
err=$?

#jobs="job1 job2"
#for job in $jobs;
#do
#    [ "$job" = "job1" ] && echo release devidx=1 $mods1
#    [ "$job" = "job2" ] && echo release devidx=2 $mods2
#done | xargs -P $process -I "{}" bash -c '{ argv=({}); echo "[*] to run ${argv[@]}"; sh run_ut.sh ${argv[@]}; }'



#if [[ "$android_ut_modules" =~ "all" ]]; then
#    sh run_ut.sh release xreport=1
#    err=$?
#fi

exit $err

###########
source ~/.bash_profile
set -x
wmepath=$WORKSPACE/$repo_loc/$wme_loc

cd $wmepath
rm -rf INFO-UT-Android*
touch INFO-UT-Android-h${parent_build_number}-j${BUILD_NUMBER}-${git_commit_revision}
mkdir -p $WORKSPACE/generatedJUnitFiles/GoogleTest/

exit 0