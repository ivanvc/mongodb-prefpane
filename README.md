mongoDB.prefpane
================

Don't you love mongoDB. Don't you hate it literally drains your memory?

Well, mongoDB prefpane is a simple shortcut to start/stop the mongoDB daemon.

![Screenshot](http://ivanvc.github.com/mongodb-prefpane/images/screenshot.png)

Installation
------------

* Download the compressed binary version from the downloads page (prefered).
* Clone the source and compile the source, then run the .prefpane generated
  (check for it in ~/Library/Developer/Xcode/DerivedData).

Updating
--------

Just open the preference pane, and [Sparkle](http://sparkle.andymatuschak.org/)
will do the magic.

Configuration
-------------

Edit the arguments, and choose the binary location, all from the UI (No more
painful configuration :).

Planned Features
----------------

* Enable/disable start mongod on login (LaunchAgents)
* Enable/disable of a menu bar item for quick access

Limitations
-----------

* It won't stop the daemon if it is running from a LaunchAgent.

Credits
-------

[DaemonController](http://github.com/ivanvc/DaemonController)

Original DaemonController and MBSliderButton based in the ones made
by [Max Howell](http://github.com/mxcl)

