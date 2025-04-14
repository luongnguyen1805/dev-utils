#!/bin/zsh

CHECK_COMPILER="$(which swift)"

if [[ "$CHECK_COMPILER" == *"not found"* ]]; then
    echo "swift NOT FOUND"
    exit 1
fi

#SOLVE error PlatformPath not found
#   sudo xcode-select -switch "/Applications/Xcode.app/Contents/Developer"                     

swift build
swift test