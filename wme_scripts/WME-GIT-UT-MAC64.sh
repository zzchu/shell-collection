source ~/.bash_profile
wmepath=$WORKSPACE/$repo_loc/$wme_loc

echo START TO GET SDK PACKAGES
mkdir -p $wmepath/distribution/mac
rm -rf $wmepath/distribution/mac/*


cd $wmepath/distribution/mac
[ "$bld_mac64_url" = "" ] && bld_mac64_url="$UPSTREAM_URL"
UPSTREAM_BASE=${bld_mac64_url}/artifact/$repo_loc/$wme_loc/distribution/mac/
curl -C - --retry 3 --retry-delay 60 -k -s -S -O -u wme-jenkins1.gen:d67f0ebb7ab2d9f33c1f96ae64c30f61 ${UPSTREAM_BASE}mac-release.tar.gz
tar -xzf mac-release.tar.gz
rm *.tar.gz

###########

source ~/.bash_profile
wmepath=$WORKSPACE/$repo_loc/$wme_loc

echo START TO BUILD AND RUN UT APP
cd $wmepath/build/mac/
rm -rf report
sh build_ut.sh -a 64 release
echo "build ut end!"

##########
source ~/.bash_profile
wmepath=$WORKSPACE/$repo_loc/$wme_loc


cd $wmepath
rm -rf INFO-UT-MAC*
touch INFO-UT-MAC-h${parent_build_number}-j${BUILD_NUMBER}-${git_commit_revision}
mkdir -p $WORKSPACE/generatedJUnitFiles/GoogleTest/

exit 0