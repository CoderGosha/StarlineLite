using Toybox.Timer;
using Toybox.Application;
using Toybox.WatchUi;

using Toybox.WatchUi;
using Toybox.System;

public enum AppState {
    IDLE = "Idle",
    SEND_COMMAND = "Send Command",
    UPDATING = "Updating"
}

class StarlineController
{
    var mTimer;
    var mAppState as AppState;
    var mCarState as CarState;
    // Initialize the controller
    function initialize() {
        // Allocate a timer
        mTimer = null;
        mAppState = IDLE;
        mCarState = new CarState();
        //mAppState = AppState.IDLE;
    }

    function SendCommand() {

        WatchUi.pushView(new WatchUi.ProgressBar("Saving...", null), null, WatchUi.SLIDE_DOWN);
        mTimer = new Timer.Timer();
        mTimer.start(method(:onExit), 3000, false);
    }

    function GetStatus() as CarState {
        return mCarState;
    }

    // Handle timing out after exit
    function onExit() {
        System.exit();
    }

}