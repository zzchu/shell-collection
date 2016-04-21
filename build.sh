#!/bin/bash
# Build media sdk libraries of iOS platform

START_TIME=$(date +%s)

echo "###################################################################"
echo "##Start to build the media SDK library"

if [ $# -gt 2 ]; then
echo "*please use command $0 [cc] [clean]"
echo "*cc      - option: enable code coverage function"
echo "*clean   - option: force to clean it before building the project"
exit 2
fi


for PARAM in $*; do
 if [ "clean" = "${PARAM}" ]; then
  PROJECT_CLEAN="clean"
 elif [ "cc" = "${PARAM}" ]; then
  CODE_COVERAGE_CONFIG="./EnableCoverage.xcconfig"
  echo "Unit Test will run with code coverage enable"
 else
  echo parameters are illegal!!!, please have a check.
  exit 2
 fi
done

# Path macro
CURRENT_PATH=`pwd`

# Set the work space path
DISTRIBUTION_PATH=${CURRENT_PATH}/../../distribution/ios
MEDIASDK_PROJECT_PATH=${CURRENT_PATH}/../../mediaengine/bld/ios
SAFEC_PROJECT_PATH=${CURRENT_PATH}/../../vendor/security/library/safec/ios/safec
CODEC_PROJECT_PATH=${CURRENT_PATH}/../../vendor/openh264/libs/ios
OPENSSL_PROJECT_PATH=${CURRENT_PATH}/../../vendor/openssl/ciscossl/libs/ios
WME_UNITTEST_IOS_STD_OUT_ERR=/dev/null



function buildProjectAllVersions()
{
if [ ${CODE_COVERAGE_CONFIG}x = "x" ]; then
xcodebuild ARCHS="armv7 armv7s" VALID_ARCHS="armv7 armv7s" ONLY_ACTIVE_ARCH=NO -project $1.xcodeproj -target $2 -configuration Debug -sdk iphoneos ${PROJECT_CLEAN} build #> ${WME_UNITTEST_IOS_STD_OUT_ERR} 2>&1
else
xcodebuild -xcconfig "${CODE_COVERAGE_CONFIG}" ARCHS="armv7 armv7s" VALID_ARCHS="armv7 armv7s" ONLY_ACTIVE_ARCH=NO -project $1.xcodeproj -target $2 -configuration Debug -sdk iphoneos ${PROJECT_CLEAN} build #> ${WME_UNITTEST_IOS_STD_OUT_ERR} 2>&1
fi

if [ $? == 0 ]; then
echo "build $1 Debug iphoneos successfully"
else
echo "build $1 Debug iphoneos fail"
return 1
fi

if [ ${CODE_COVERAGE_CONFIG}x = "x" ]; then
xcodebuild ARCHS="armv7 armv7s" VALID_ARCHS="armv7 armv7s" ONLY_ACTIVE_ARCH=NO -project $1.xcodeproj -target $2 -configuration Release -sdk iphoneos ${PROJECT_CLEAN} build #> ${WME_UNITTEST_IOS_STD_OUT_ERR} 2>&1
else
xcodebuild -xcconfig "${CODE_COVERAGE_CONFIG}" ARCHS="armv7 armv7s" VALID_ARCHS="armv7 armv7s" ONLY_ACTIVE_ARCH=NO -project $1.xcodeproj -target $2 -configuration Release -sdk iphoneos ${PROJECT_CLEAN} build #> ${WME_UNITTEST_IOS_STD_OUT_ERR} 2>&1
fi

if [ $? == 0 ]; then
echo "build $1 Release iphoneos successfully"
else
echo "build $1 Release iphoneos fail"
return 1
fi

if [ ${CODE_COVERAGE_CONFIG}x = "x" ]; then
xcodebuild ARCHS="i386" VALID_ARCHS="i386" ONLY_ACTIVE_ARCH=NO -project $1.xcodeproj -target $2 -configuration Debug -sdk iphonesimulator ${PROJECT_CLEAN} build #> ${WME_UNITTEST_IOS_STD_OUT_ERR} 2>&1
else
xcodebuild -xcconfig "${CODE_COVERAGE_CONFIG}" ARCHS="i386" VALID_ARCHS="i386" ONLY_ACTIVE_ARCH=NO -project $1.xcodeproj -target $2 -configuration Debug -sdk iphonesimulator ${PROJECT_CLEAN} build #> ${WME_UNITTEST_IOS_STD_OUT_ERR} 2>&1
fi

if [ $? == 0 ]; then
echo "build $1 Debug iphonesimulator successfully"
else
echo "build $1 Debug iphonesimulator fail"
return 1
fi

if [ ${CODE_COVERAGE_CONFIG}x = "x" ]; then
xcodebuild ARCHS="i386" VALID_ARCHS="i386" ONLY_ACTIVE_ARCH=NO -project $1.xcodeproj -target $2 -configuration Release -sdk iphonesimulator ${PROJECT_CLEAN} build #> ${WME_UNITTEST_IOS_STD_OUT_ERR} 2>&1
else
xcodebuild -xcconfig "${CODE_COVERAGE_CONFIG}" ARCHS="i386" VALID_ARCHS="i386" ONLY_ACTIVE_ARCH=NO -project $1.xcodeproj -target $2 -configuration Release -sdk iphonesimulator ${PROJECT_CLEAN} build #> ${WME_UNITTEST_IOS_STD_OUT_ERR} 2>&1
fi

if [ $? == 0 ]; then
echo "build $1 Release iphonesimulator successfully"
else
echo "build $1 Release iphonesimulator fail"
return 1
fi

return 0
}

# Build common and media sdk libraries
PROJECT_FILE_NAME="MediaSDKClient"
TARGET_NAME="BuildAll"

buildProjectAllVersions ${MEDIASDK_PROJECT_PATH}/${PROJECT_FILE_NAME} ${TARGET_NAME}
if [ $? != 0 ]; then
echo "Build ${PROJECT_FILE_NAME} failed, exit now"
exit 1
fi

# Build vender libraries
PROJECT_FILE_NAME="safec"
TARGET_NAME="safec"

buildProjectAllVersions ${SAFEC_PROJECT_PATH}/${PROJECT_FILE_NAME} ${TARGET_NAME}
if [ $? != 0 ]; then
echo "Build ${PROJECT_FILE_NAME} failed, exit now"
exit 1
fi

# Build common and media sdk libraries
#cd ${MEDIASDK_PROJECT_PATH}
#xcodebuild -xcconfig ${CODE_COVERAGE_CONFIG} ARCHS="armv7 armv7s" VALID_ARCHS="armv7 armv7s" -project MediaSDKClient.xcodeproj -target BuildAll -configuration Debug -sdk iphoneos clean build
#xcodebuild -xcconfig ${CODE_COVERAGE_CONFIG} ARCHS="armv7 armv7s" VALID_ARCHS="armv7 armv7s" -project MediaSDKClient.xcodeproj -target BuildAll -configuration Release -sdk iphoneos clean build
#xcodebuild -xcconfig ${CODE_COVERAGE_CONFIG} ARCHS="i386" VALID_ARCHS="i386" -project MediaSDKClient.xcodeproj -target BuildAll -configuration Debug -sdk iphonesimulator clean build
#xcodebuild -xcconfig ${CODE_COVERAGE_CONFIG} ARCHS="i386" VALID_ARCHS="i386" -project MediaSDKClient.xcodeproj -target BuildAll -configuration Release -sdk iphonesimulator clean build

# Build vender libraries
#cd ${SAFEC_PROJECT_PATH}
#xcodebuild -xcconfig ${CODE_COVERAGE_CONFIG} ARCHS="armv7 armv7s" VALID_ARCHS="armv7 armv7s" -project safec.xcodeproj -target safec -configuration Debug -sdk iphoneos clean build
#xcodebuild -xcconfig ${CODE_COVERAGE_CONFIG} ARCHS="armv7 armv7s" VALID_ARCHS="armv7 armv7s" -project safec.xcodeproj -target safec -configuration Release -sdk iphoneos clean build
#xcodebuild -xcconfig ${CODE_COVERAGE_CONFIG} ARCHS="i386" VALID_ARCHS="i386" -project safec.xcodeproj -target safec -configuration Debug -sdk iphonesimulator clean build
#xcodebuild -xcconfig ${CODE_COVERAGE_CONFIG} ARCHS="i386" VALID_ARCHS="i386" -project safec.xcodeproj -target safec -configuration Release -sdk iphonesimulator clean build

# Copy codec library
cd ${CODEC_PROJECT_PATH}
cp -f ${CODEC_PROJECT_PATH}/Debug-iphoneos/*.a ${DISTRIBUTION_PATH}/Debug-iphoneos/
cp -f ${CODEC_PROJECT_PATH}/Debug-iphonesimulator/*.a ${DISTRIBUTION_PATH}/Debug-iphonesimulator/
cp -f ${CODEC_PROJECT_PATH}/Release-iphoneos/*.a ${DISTRIBUTION_PATH}/Release-iphoneos/
cp -f ${CODEC_PROJECT_PATH}/Release-iphonesimulator/*.a ${DISTRIBUTION_PATH}/Release-iphonesimulator/


# Copy openssl library
cd ${OPENSSL_PROJECT_PATH}
cd ${CODEC_PROJECT_PATH}
cp -f ${OPENSSL_PROJECT_PATH}/Debug-iphoneos/*.a ${DISTRIBUTION_PATH}/Debug-iphoneos/
cp -f ${OPENSSL_PROJECT_PATH}/Debug-iphonesimulator/*.a ${DISTRIBUTION_PATH}/Debug-iphonesimulator/
cp -f ${OPENSSL_PROJECT_PATH}/Release-iphoneos/*.a ${DISTRIBUTION_PATH}/Release-iphoneos/
cp -f ${OPENSSL_PROJECT_PATH}/Release-iphonesimulator/*.a ${DISTRIBUTION_PATH}/Release-iphonesimulator/


cd ${CURRENT_PATH}
END_TIME=$(date +%s)
((BUILD_TIME=${END_TIME}-${START_TIME}))
echo "the building time is: ${BUILD_TIME} seconds"

exit 0
