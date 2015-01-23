#!/bin/sh

pushd `dirname $0`
mkdir -p ~/Library/Developer/Xcode/Templates/Project\ Templates
cp -r Templates/Project\ Templates/Android ~/Library/Developer/Xcode/Templates/Project\ Templates/
popd