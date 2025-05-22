#!/bin/bash

checkExit(){
    if [ $? != 0 ]; then
        echo "Building failed: $1\n"
        exit 1
    fi
}

CHANGELOG=$(cat CHANGELOG.md)
VERSION_REGEX='## *\[([.0-9]*)\]'
CURRENT_VERSION=""
if [[ $CHANGELOG =~ $VERSION_REGEX ]]; then
    CURRENT_VERSION=${BASH_REMATCH[1]}
fi

echo "Release version $CURRENT_VERSION detected"

APP_CONFIG_PATH="./build.config"
echo "CURRENT_VERSION=$CURRENT_VERSION" > "$APP_CONFIG_PATH"

swift MakeImageLinter.swift -version "$CURRENT_VERSION"

#cd Examples/2.x
#checkExit "Start Tests"

#xcrun simctl shutdown all
#sh ../../Scripts/build.sh -c Debug -p Example -test 'platform=iOS Simulator,name=iPhone 15,OS=17.2'
#checkExit "Tests on iOS 17.2"
