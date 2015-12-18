Running Autopilot tests
=======================

The Music app follows a test driven development where autopilot tests are run before every merge into trunk. If you are submitting your bugfix/patch to the Music app, please follow the following steps below to ensure that all tests pass before proposing a merge request.

If you are looking for more info about Autopilot or writing AP tests for the music app, here are some useful links to help you:

- [Ubuntu - Quality](http://developer.ubuntu.com/start/quality)
- [Autopilot - Python](https://developer.ubuntu.com/api/autopilot/python/1.5.0/)

For help and options on running tests, see:

- [Autopilot tests](https://developer.ubuntu.com/en/start/platform/guides/running-autopilot-tests/)

Prerequisites
=============

Install the following autopilot packages required to run the tests,

    $ sudo apt-get install python3-autopilot libautopilot-qt ubuntu-ui-toolkit-autopilot python3-autopilot-vis

Running tests on the desktop
============================

Using terminal:

*  Branch the Music app code, for example,

    $ bzr branch lp:music-app
    
*  Navigate to the tests/autopilot directory.

    $ cd music-app/tests/autopilot

*  run all tests.

    $ autopilot3 run -vv music_app

* to list all tests:

    $ autopilot3 list music_app

 To run only one test (for instance:  music_app.tests.test_music.TestMainWindow.test_swipe_to_delete_song)

    $ autopilot3 run -vv music_app.tests.test_music.TestMainWindow.test_swipe_to_delete_song

* Debugging tests using autopilot vis

    $ autopilot3 launch -i Qt qmlscene app/music-app.qml

    $ autopilot3 vis

Running tests using Ubuntu SDK
==============================

Refer this [tutorial](https://developer.ubuntu.com/en/start/platform/guides/running-autopilot-tests/) to run tests on Ubuntu SDK: 

Running tests on device or emulator:
====================================

## Set up the system

Prior to running tests on the device, follow the steps to find music in the system.

    $ mv /home/phablet/Music /home/phablet/.Music
    $ restart mediascanner-2.0

Using autopkg:

*  Branch the Music app code, for example,

    $ bzr branch lp:music-app

*  Navigate to the source directory.

    $ cd music-app

*  Build a click package
    
    $ click-buddy .

*  Run the tests on device (assumes only one click package in the directory)

$ adt-run . *.click --- ssh -s adb -- -p <PASSWORD>

*  Resolving mediascanner2 schema issues when tests fail

Occasionally the schema for the mediascanner2 (ms2) service is incremented and updates to the mocked ms2 database are required. The following steps should be taken to update the database and sql file when this happens.

1. Dump a new schema file for the database for debugging:
   $ sqlite3 ~/.cache/mediascanner-2.0/mediastore.db .sch > tests/autopilot/music_app/content/mediascanner-2.0/mediastore.sch

2. Edit the SQL file to use the new schemaVersion number:
   $ vi tests/autopilot/music_app/content/mediascanner-2.0/mediastore.sql

3. If the tests still do not pass, execute the following bzr command to debug what has changed in the schema and update the SQL file to insert the values for each column in the 'media' table accordingly:
   $ bzr diff tests/autopilot/music_app/content/mediascanner-2.0/mediastore.sch
   $ vi tests/autopilot/music_app/content/mediascanner-2.0/mediastore.sql

