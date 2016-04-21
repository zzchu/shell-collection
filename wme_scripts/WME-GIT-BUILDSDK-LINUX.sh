#!/bin/bash  --login
source ~/.bash_profile
wmepath=$WORKSPACE/$repo_loc/$wme_loc

exit 0
echo START TO CLEAN ALL PREVIOUS GENERATED PACKAGE
echo "[*] to clean old package"
cd $wmepath
git clean -dfx

echo START TO GET THE SUBMODULES
git submodule update --init --recursive

cd $wmepath/vendor/code-style
git checkout .
git clean -d -f -x

cd $wmepath/vendor/libsdp
git checkout .
git clean -d -f -x

cd $wmepath/vendor/mari
git checkout .
git clean -d -f -x

cd $wmepath/build/linux
echo START TO BUILD SDK
err=0
echo "[*] to build wme linux"
sh build.sh  || exit 1

echo "[*] to build linux UT"
sh build_ut.sh  || exit 1

echo "[*] to run linux UT"
sh run_ut.sh  || exit 1

echo "[*] to package linux package"
bash package.sh  || exit 1


exit 0