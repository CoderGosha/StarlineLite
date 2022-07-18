using Toybox.Timer;
using Toybox.Application;
using Toybox.WatchUi;

using Toybox.WatchUi;
using Toybox.System;

public enum AppState {
    IDLE = "Idle",
    SEND_COMMAND = "Send Command",
    UPDATING = "Updating",
    NULL_CREDENTIAL = "Null_Credential"
}

class StarlineController
{
    public var AppState as AppState;

    var mTimer;
    var mCarState as CarState;
    var mLogin as String;
    var mPass as String;
    var mUrl as String;

    // Initialize the controller
    function initialize() {
        // Allocate a timer
        mTimer = null;
        AppState = IDLE;
        mCarState = new CarState();
        //mAppState = AppState.IDLE;
    }

    function SendCommand() {

        WatchUi.pushView(new WatchUi.ProgressBar("Saving...", null), null, WatchUi.SLIDE_DOWN);
        mTimer = new Timer.Timer();
        mTimer.start(method(:onExit), 3000, false);
    }

    function GetCarState() as CarState {
        // TODO async 
        RefreshCarState();
        return mCarState;
    }

    function UpdateCredentials() {
        mLogin = Application.Properties.getValue("starline_API_user");
        mPass = Application.Properties.getValue("starline_API_pass");
        mUrl = Application.Properties.getValue("starline_API_URL");
    }

    function CheckAccess() as Boolean
    {
        UpdateCredentials();
        if ((mLogin == Application.Properties.getValue("starline_API_user_default")) 
        || (mPass == Application.Properties.getValue("starline_API_pass_default"))){
            AppState = NULL_CREDENTIAL;
            return false;
        }

        return true;
    }

    function RefreshCarState() {
        CheckAccess();
    }

    // Handle timing out after exit
    function onExit() {
        System.exit();
    }

}