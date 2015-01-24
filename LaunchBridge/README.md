#About LaunchBridge

Ideally, we want build,run,and debug android app in Xcode, just like normal iOS application. But to achieve this goal, we needs to do a lot of hard things, like digging into Xcode, figure out the device manage,communication mechanism, etc..

Due to the limited time for this project. we choose write a bridge  tool instead.

this tool does threse things:

* install android application
* launch android application
* forware android logcat to Xcode