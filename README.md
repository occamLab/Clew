# clew
breadcrumbs app for path retracing

## Contents
- [Overview](#overview)
- [Setup and dependencies](#setup-and-dependencies)
  - [First time setup](#first-time-setup)
  - [How to run](#how-to-run)
  - [How to contribute](#how-to-contribute)
- [Architecture](#architecture)
- [Troubleshooting and resources](#troubleshooting-and-resources)

## Overview

Clew is a path retracing app designed for blind and visually impaired users to help them independently return to any desired locations. Clew is designed with finding your way back to a seat or a table in mind and works best indoors over relatively short distances.

Clew uses Apple's ARKit to record a path through space. As you record a path, it keeps track of the path by leaving virtual breadcrumbs. When you're ready to return back to your starting point, it converts those breadcrumbs into keypoints - points where you turned or climbed stairs. The app can then give you instructions to each keypoint and help you navigate back to your starting point. More information is available on the [website](www.clewapp.org "Clew website").

Clew is an [OCCaM Lab](http://occam.olin.edu/) project currently under development.

Right now, we're focused on updating documentation and rearchitecturing some of the codebase.

Future work with Clew may include:
- bug fix: stop speaking over first instructions on a route
- new feature: save a route
- new feature: run in background
- new feature: integrate with other apps (e.g. Blindsquare)

## Setup and dependencies

Clew is written in Swift 4 with Xcode 9 and should work on any iPhone with an A9 or later processor.

### First time setup

Please read all of this! It's important.

Get the repository on your computer: clone the `assistive_apps` repository and `cd` into the Clew directory (`cd assistive_apps/navigation/ios_apps/ClewApp`).

Install the Pods: if you don't have CocoaPods on your Mac, run `sudo gem install cocoapods`. Then, to install the Pods for Clew, run `pod install` from inside the `ClewApp` directory.

Open the project: from the `ClewApp` directory, run `open Clew.xcworkspace`. Because this project uses CocoaPods, it's important to always open the workspace, instead of the Xcode project. (If you use the filesystem GUI instead of the Terminal, double click on Clew.xcworkspace to open it.)

### How to run

Navigate to the `ClewApp` directory and type `open Clew.xcworkspace` in the Terminal.

### How to contribute

#### Branching and pull requests
This project uses a feature branching workflow. Make a new branch if you're going to implement a feature. Pull requests (and at least one review) are required before merging to `master`. Pull `master` into your branch before pull requesting so you don't create merge conflicts on `master`.

#### Documentation
Before you pull request, make sure the README is up to date, everything you added or updated in the code is appropriately and accurately commented (both inline and header doc), and update the jazzy documentation. OCCaM Lab's documentation guidelines are available on the Google Drive or by request. To update the jazzy docs, run `jazzy --min-acl internal`. If jazzy is not installed on your Mac, run `sudo gem install jazzy`.

#### CocoaPods

Check out the [CocoaPods docs](cocoapods.org "CocoaPods website") for information for adding a new Pod. Make sure to use CocoaPods, if possible, when adding a new library!

If something goes wrong, check what's written in the Podfile. Because this app has multiple targets, make sure to specify the Pod in the correct section (probably all_pods). 

#### Adding new files

This project has multiple targets! You probably want to add any files to both Clew and Clew Dev, so make sure to choose that when the Xcode popup asks. For more information about using multiple targets, check out [this tutorial](https://www.appcoda.com/using-xcode-targets "Using Xcode Targets").

## Architecture
<!-- TODO: describe architecture -->

## Troubleshooting and resources

### Developer signing error

If your build (to a real phone, instead of a simulator) fails because of a developer signing error, click on Clew in the project navigator (Clew should be the first entry and on the lowest level). Choose to revoke the certificate and follow instructions after that.

### CocoaPods

For more information on how to use or troubleshoot CocoaPods, check out their [useful website](https://cocoapods.org/ "CocoaPods website").

### Jazzy

For more information on how to use or troubleshoot jazzy, check out their [project on GitHub](https://github.com/realm/jazzy "Jazzy on GitHub").

### Multiple Targets

Right now, you can choose to build to Clew or to Clew Dev. This means you can build it on an iPhone without overwriting the App Store version of Clew, if you have it. 

If there are problems, most of the steps taken to make this happen are from [this tutorial](https://www.appcoda.com/using-xcode-targets "Using Xcode Targets") and therefore most of the places to check for errors are as well.
