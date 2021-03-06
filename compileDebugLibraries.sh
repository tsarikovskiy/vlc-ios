#!/bin/sh
# Copyright (C) Pierre d'Herbemont, 2010
# Copyright (C) Felix Paul Kühne, 2012-2015

set -e

SDK=`xcrun --sdk iphoneos --show-sdk-version`
SDK_MIN=7.0
VERBOSE=no
CONFIGURATION="Release"
NONETWORK=no
SKIPLIBVLCCOMPILATION=no
TVOS=no

TESTEDVLCKITHASH=a0bf5544
TESTEDMEDIALIBRARYKITHASH=f8142c56

usage()
{
cat << EOF
usage: $0 [-v] [-k sdk] [-d] [-n] [-l] [-t]

OPTIONS
   -k       Specify which sdk to use (see 'xcodebuild -showsdks', current: ${SDK})
   -v       Be more verbose
   -d       Enable Debug
   -n       Skip script steps requiring network interaction
   -l       Skip libvlc compilation
   -t       Build for TV
EOF
}

spushd()
{
     pushd "$1" 2>&1> /dev/null
}

spopd()
{
     popd 2>&1> /dev/null
}

info()
{
     local green="\033[1;32m"
     local normal="\033[0m"
     echo "[${green}info${normal}] $1"
}

while getopts "hvsdtnluk:" OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         v)
             VERBOSE=yes
             ;;
         d)  CONFIGURATION="Debug"
             ;;
         n)
             NONETWORK=yes
             ;;
         l)
             SKIPLIBVLCCOMPILATION=yes
             ;;
         k)
             SDK=$OPTARG
             ;;
         t)
             TVOS=yes
             SDK=`xcrun --sdk appletvos --show-sdk-version`
             SDK_MIN=9.0
             ;;
         ?)
             usage
             exit 1
             ;;
     esac
done
shift $(($OPTIND - 1))

out="/dev/null"
if [ "$VERBOSE" = "yes" ]; then
   out="/dev/stdout"
fi

if [ "x$1" != "x" ]; then
    usage
    exit 1
fi

info "Preparing build dirs"

mkdir -p ImportedSources

spushd ImportedSources

if [ "$NONETWORK" != "yes" ]; then
if ! [ -e MediaLibraryKit ]; then
git clone http://code.videolan.org/videolan/MediaLibraryKit.git
cd MediaLibraryKit
# git reset --hard ${TESTEDMEDIALIBRARYKITHASH}
cd ..
else
cd MediaLibraryKit
git pull --rebase
# git reset --hard ${TESTEDMEDIALIBRARYKITHASH}
cd ..
fi
if ! [ -e VLCKit ]; then
git clone http://code.videolan.org/videolan/VLCKit.git
cd VLCKit
git reset --hard ${TESTEDVLCKITHASH}
cd ..
else
cd VLCKit
git pull --rebase
git reset --hard ${TESTEDVLCKITHASH}
cd ..
fi
fi

spopd #ImportedSources

#
# Build time
#

info "Building"

spushd ImportedSources

spushd VLCKit
echo `pwd`
args=""
if [ "$VERBOSE" = "yes" ]; then
    args="${args} -v"
fi
if [ "$NONETWORK" = "yes" ]; then
    args="${args} -n"
fi
if [ "$SKIPLIBVLCCOMPILATION" = "yes" ]; then
    args="${args} -l"
fi
if [ "$TVOS" = "yes" ]; then
    args="${args} -t"
fi
./buildMobileVLCKit.sh ${args} -k "${SDK}"
spopd

spopd # ImportedSources

#install pods
info "installing pods"
pod install

info "Build completed"
