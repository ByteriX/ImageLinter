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

checkExit "Start to make ImageLinter.swift script"

swift Scripts/MakeImageLinter.swift -version "$CURRENT_VERSION"

checkExit "Finished ImageLinter.swift script"
