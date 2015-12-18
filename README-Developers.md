Building and running on Desktop
===============================

Building and running the Ubuntu Music App is quite simple. You will require
Ubuntu 15.04 and higher to run on the desktop.

   

    $ bzr branch lp:music-app branch-name
    $ cd branch-name
    $ qmlscene app/music-app.qml

Submitting a patch upstream
===========================

If you want to submit a bug fix you can do so by branching the code as shown
above, implementing the fixes and running to see if it fixed the issue. We also
request that you run the Autopilot tests to check if anything
regressed due to the bug fix.

If the tests fail, you will have to fix them before your bug fix can be
approved and merged into trunk. If the tests pass then commit and push your
code by,

   

    $ bzr commit -m "Implemented bug fix" --fixes lp:bug-number
    $ bzr push lp:~launchpadid/music-app/branch-name

Running Tests
=============

Please check README-Autopilot.md on how to run the tests.
They are quite explanatory and will help you get started.

Code Style
==========

We are trying to use a common code style throughout the code base to maintain
uniformity and improve code clarity. Listed below are the code styles guides
that will be followed based on the language used.

* [QML](http://qt-project.org/doc/qt-5/qml-codingconventions.html) 
* [JS, C++](https://google-styleguide.googlecode.com/svn/trunk/cppguide.xml) 
* Python     - Code should follow PEP8 and Flake regulations

Note: In the QML code convention, ignore the Javascript code section guidelines.
So the sections that should be taken into account in the QML conventions are QML 
Object Declarations, Grouped Properties and Lists.

Debugging
=========
 
GDB allows one to see what is going on `inside' another program while it executes, 
or what another program was doing at the moment it crashed. It is a pretty niffty tool which allows you 
to get the crash log that can help a developer pin point the cause of the crash.
Before reproducing crash it is good to create symbols table for gdb, by using command:

   

    $ cd branch-name	

To run GDB:

   

    $ gdb qmlscene

At this point, you are inside the gdb prompt. Run your application as you normally would.

     run app/music-app.qml

Your app is now running and monitored by GDB. Reproduce the steps in your app to make it crash. Once it does crash,

     bt

That's about it. To quit GDB, type quit to return back to the normal terminal console.

     quit



