#! /bin/sh

BASEDIR=$(dirname $0)

# AAX codesigning requires ashelper tool in /usr/local/bin and aax.key/.crt in ./../../../Certificates/


cd $BASEDIR

#---------------------------------------------------------------------------------------------------------

#variables

VERSION=`echo | grep PLUG_VER resource.h`
VERSION=${VERSION//\#define PLUG_VER }
VERSION=${VERSION//\'}
MAJOR_VERSION=$(($VERSION & 0xFFFF0000))
MAJOR_VERSION=$(($MAJOR_VERSION >> 16)) 
MINOR_VERSION=$(($VERSION & 0x0000FF00))
MINOR_VERSION=$(($MINOR_VERSION >> 8)) 
BUG_FIX=$(($VERSION & 0x000000FF))

FULL_VERSION=$MAJOR_VERSION"."$MINOR_VERSION"."$BUG_FIX

# work out the paths to the bundles

VST2=`echo | grep VST_FOLDER ../../common.xcconfig`
VST2=${VST2//\VST_FOLDER = }/DelayIdeaz.vst

VST3=`echo | grep VST3_FOLDER ../../common.xcconfig`
VST3=${VST3//\VST3_FOLDER = }/DelayIdeaz.vst3

AU=`echo | grep AU_FOLDER ../../common.xcconfig`
AU=${AU//\AU_FOLDER = }/DelayIdeaz.component

APP=`echo | grep APP_FOLDER ../../common.xcconfig`
APP=${APP//\APP_FOLDER = }/DelayIdeaz.app

# Dev build folder
RTAS=`echo | grep RTAS_FOLDER ../../common.xcconfig`
RTAS=${RTAS//\RTAS_FOLDER = }/DelayIdeaz.dpm
RTAS_FINAL="/Library/Application Support/Digidesign/Plug-Ins/DelayIdeaz.dpm"

# Dev build folder
AAX=`echo | grep AAX_FOLDER ../../common.xcconfig`
AAX=${AAX//\AAX_FOLDER = }/DelayIdeaz.aaxplugin
AAX_FINAL="/Library/Application Support/Avid/Audio/Plug-Ins/DelayIdeaz.aaxplugin"

PKG='installer/build-mac/DelayIdeaz Installer.pkg'
PKG_US='installer/build-mac/DelayIdeaz Installer.unsigned.pkg'

CERT_ID=`echo | grep CERTIFICATE_ID ../../common.xcconfig`
CERT_ID=${CERT_ID//\CERTIFICATE_ID = }

echo "making DelayIdeaz version $FULL_VERSION mac distribution..."
echo ""

#---------------------------------------------------------------------------------------------------------

./update_version.py

#could use touch to force a rebuild
#touch blah.h

#---------------------------------------------------------------------------------------------------------

#remove existing dist folder
#if [ -d installer/dist ] 
#then
#  rm -R installer/dist
#fi

#mkdir installer/dist

#remove existing binaries
if [ -d $APP ] 
then
  sudo rm -f -R -f $APP
fi

if [ -d $AU ] 
then
  sudo rm -f -R $AU
fi

if [ -d $VST2 ] 
then
  sudo rm -f -R $VST2
fi

if [ -d $VST3 ] 
then
  sudo rm -f -R $VST3
fi

if [ -d "${RTAS}" ] 
then
  sudo rm -f -R "${RTAS}"
fi

if [ -d "${RTAS_FINAL}" ] 
then
  sudo rm -f -R "${RTAS_FINAL}"
fi

if [ -d "${AAX}" ] 
then
  sudo rm -f -R "${AAX}"
fi

if [ -d "${AAX_FINAL}" ] 
then
  sudo rm -f -R "${AAX_FINAL}"
fi

#---------------------------------------------------------------------------------------------------------

# build xcode project. Change target to build individual formats 
xcodebuild -project DelayIdeaz.xcodeproj -xcconfig DelayIdeaz.xcconfig -target "All" -configuration Release 2> ./build-mac.log
#xcodebuild -project DelayIdeaz-ios.xcodeproj -xcconfig DelayIdeaz.xcconfig -target "IOSAPP" -configuration Release

if [ -s build-mac.log ]
then
  echo "build failed due to following errors:"
  echo ""
  cat build-mac.log
  exit 1
else
 rm build-mac.log
fi

#---------------------------------------------------------------------------------------------------------

#icon stuff - http://maxao.free.fr/telechargements/setfileicon.gz
echo "setting icons"
echo ""
setfileicon resources/DelayIdeaz.icns $AU
setfileicon resources/DelayIdeaz.icns $VST2
setfileicon resources/DelayIdeaz.icns $VST3
setfileicon resources/DelayIdeaz.icns "${RTAS}"
setfileicon resources/DelayIdeaz.icns "${AAX}"

#---------------------------------------------------------------------------------------------------------

#ProTools stuff

echo "copying RTAS bundle from 3PDev to main RTAS folder"
sudo cp -p -R "${RTAS}" "${RTAS_FINAL}"

echo "copying AAX bundle from 3PDev to main AAX folder"
sudo cp -p -R "${AAX}" "${AAX_FINAL}"

echo "code sign AAX binary"
sudo ashelper -f "${AAX_FINAL}/Contents/MacOS/DelayIdeaz" -l ../../../Certificates/aax.crt -k ../../../Certificates/aax.key -o "${AAX_FINAL}/Contents/MacOS/DelayIdeaz"
#---------------------------------------------------------------------------------------------------------

#appstore stuff

# echo "code signing app for appstore"
# echo ""
# codesign -f -s "3rd Party Mac Developer Application: ""${CERT_ID}" $APP --entitlements resources/DelayIdeaz.entitlements
#  
# echo "building pkg for app store"
# productbuild \
#      --component $APP /Applications \
#      --sign "3rd Party Mac Developer Installer: ""${CERT_ID}" \
#      --product "/Applications/DelayIdeaz.app/Contents/Info.plist" installer/DelayIdeaz.pkg

#---------------------------------------------------------------------------------------------------------

#10.8 Gatekeeper/Developer ID stuff

#echo "code sign app for Gatekeeper on 10.8"
#echo ""
#codesign -f -s "Developer ID Application: ""${CERT_ID}" $APP

#---------------------------------------------------------------------------------------------------------

# installer, uses Packages http://s.sudre.free.fr/Software/Packages/about.html
sudo sudo rm -R -f installer/DelayIdeaz-mac.dmg

echo "building installer"
echo ""
packagesbuild installer/DelayIdeaz.pkgproj

#echo "code sign installer for Gatekeeper on 10.8"
#echo ""
#mv "${PKG}" "${PKG_US}"
#productsign --sign "Developer ID Installer: ""${CERT_ID}" "${PKG_US}" "${PKG}"
                   
#rm -R -f "${PKG_US}"

#set installer icon
setfileicon resources/DelayIdeaz.icns "${PKG}"

#---------------------------------------------------------------------------------------------------------

# dmg, can use dmgcanvas http://www.araelium.com/dmgcanvas/ to make a nice dmg

echo "building dmg"
echo ""

if [ -d installer/DelayIdeaz.dmgCanvas ]
then
  dmgcanvas installer/DelayIdeaz.dmgCanvas installer/DelayIdeaz-mac.dmg
else
  hdiutil create installer/DelayIdeaz.dmg -srcfolder installer/build-mac/ -ov -anyowners -volname DelayIdeaz
  
  if [ -f installer/DelayIdeaz-mac.dmg ]
  then
   rm -f installer/DelayIdeaz-mac.dmg
  fi
  
  hdiutil convert installer/DelayIdeaz.dmg -format UDZO -o installer/DelayIdeaz-mac.dmg
  sudo rm -R -f installer/DelayIdeaz.dmg
fi

sudo rm -R -f installer/build-mac/

#---------------------------------------------------------------------------------------------------------
# zip

# echo "copying binaries..."
# echo ""
# cp -R $AU installer/dist/DelayIdeaz.component
# cp -R $VST2 installer/dist/DelayIdeaz.vst
# cp -R $VST3 installer/dist/DelayIdeaz.vst3
# cp -R $RTAS installer/dist/DelayIdeaz.dpm
# cp -R $AAX installer/dist/DelayIdeaz.aaxplugin
# cp -R $APP installer/dist/DelayIdeaz.app
# 
# echo "zipping binaries..."
# echo ""
# ditto -c -k installer/dist installer/DelayIdeaz-mac.zip
# rm -R installer/dist

#---------------------------------------------------------------------------------------------------------

echo "done"