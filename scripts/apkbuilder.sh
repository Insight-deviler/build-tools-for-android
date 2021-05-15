CUR_PATH=`pwd`
#OUT_NAME=${CUR_PATH##*/}
OUTPUT_NAME=release

# Check 'res' directory
if [ ! -d "res" ];then
    echo "Cannot find 'res' directory."
    exit
fi

# Check 'src' directory
if [ ! -d "src" ];then
    echo "Cannot find 'src' directory."
    exit
fi

echo "Generate R.java"
if [ ! -d "gen" ];then
    mkdir gen
fi
${ROOT_PATH}/bin/aapt package -m \
    -J gen \
    -M AndroidManifest.xml \
    -S res \
    -I ${ROOT_PATH}/bin/android.jar

export ANDROID_DATA=${ROOT_PATH}/val/android
mkdir -p ${ANDROID_DATA}/dalvik-cache

echo "Compile java code"
/system/bin/dalvikvm -Djava.io.tmpdir=${ROOT_PATH}/tmp  -Xmx256m \
    -cp ${ROOT_PATH}/bin/ecj.jar \
    org.eclipse.jdt.internal.compiler.batch.Main \
    -proc:none \
    -7 \
    -cp ${ROOT_PATH}/bin/android.classes.jar \
    -cp gen \
    -d bin/classes \
    -sourcepath src $(find src -type f -name "*.java")

echo "Convert classes to dex"
/system/bin/dalvikvm  -Xmx256m \
    -cp ${ROOT_PATH}/bin/dx.dex \
    dx.dx.command.Main --dex --output=./bin/classes.dex ./bin/classes

echo "Package resources"
RET=`${ROOT_PATH}/bin/aapt 2>&1 |grep no-version-vectors`
if [[ $RET = *"--no-version-vectors"* ]]
then
  if [ -d "assets/" ]
  then
    ${ROOT_PATH}/bin/aapt package -f \
      -I ${ROOT_PATH}/bin/android.jar \
      -S res \
      -M AndroidManifest.xml \
      -A assets \
      -F bin/${OUTPUT_NAME}.apk \
      --no-version-vectors
  else
    ${ROOT_PATH}/bin/aapt package -f \
      -I ${ROOT_PATH}/bin/android.jar \
      -S res \
      -M AndroidManifest.xml \
      -F bin/${OUTPUT_NAME}.apk \
      --no-version-vectors
  fi
else
  if [ -d "assets/" ]
  then
  ${ROOT_PATH}/bin/aapt package -f \
    -I ${ROOT_PATH}/bin/android.jar \
    -S res \
    -M AndroidManifest.xml \
    -A assets \
    -F bin/${OUTPUT_NAME}.apk
  else
  ${ROOT_PATH}/bin/aapt package -f \
    -I ${ROOT_PATH}/bin/android.jar \
    -S res \
    -M AndroidManifest.xml \
    -F bin/${OUTPUT_NAME}.apk
  fi
fi

cd bin
${ROOT_PATH}/bin/aapt add -f ${OUTPUT_NAME}.apk classes.dex

echo "Sign the APK"
#/system/bin/dalvikvm -cp ${ROOT_PATH}/bin/apksigner.dex net.fornwall.apksigner.Main -p 123456 ${ROOT_PATH}/keys/builder.jks ${OUTPUT_NAME}.apk ${OUTPUT_NAME}.signed.apk
/system/bin/dalvikvm -cp ${ROOT_PATH}/bin/apksigner.dex net.fornwall.apksigner.Main -p android ${ROOT_PATH}/keys/test.jks ${OUTPUT_NAME}.apk ${OUTPUT_NAME}.signed.apk

echo "APK Saved to" `pwd`"/"${OUTPUT_NAME}.signed.apk

cd ..