#!/bin/bash

# if you get an error try following this advice:
# https://stackoverflow.com/questions/9849034/how-to-run-install-xcodebuild

jazzy -x -workspace,Clew.xcworkspace,-scheme,Clew -g https://github.com/occamLab/Clew  --min-acl internal
