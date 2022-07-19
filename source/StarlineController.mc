using Toybox.Timer;
using Toybox.Application;
using Toybox.WatchUi;

using Toybox.WatchUi;
using Toybox.System;

public enum AppState {
    IDLE = "Idle",
    SEND_COMMAND = "Send Command",
    UPDATING = "Updating",
    NULL_CREDENTIAL = "Null_Credential",
    ERROR_RESPONSE = "ERROR_RESPONSE"
}

class StarlineController
{
    public var AppState as AppState;

    var mTimer;
    var mCarState as CarState;
    var mLogin as String;
    var mPass as String;
    var mUrl as String;
    var mStarlineClient as StarlineClient;

    // Initialize the controller
    function initialize() {
        // Allocate a timer
        mTimer = null;
        AppState = IDLE;
        mCarState = new CarState();
        mStarlineClient = new StarlineClient();
        //mAppState = AppState.IDLE;
    }

    function SendCommand() {

        WatchUi.pushView(new WatchUi.ProgressBar("Saving...", null), null, WatchUi.SLIDE_DOWN);
        mTimer = new Timer.Timer();
        mTimer.start(method(:onExit), 3000, false);
    }

    function RefreshCarState() 
    {
        if (((AppState == IDLE) || (AppState == ERROR_RESPONSE)) && (CheckAccess()))
        {
            AppState = UPDATING;
            mStarlineClient.RefreshCarState(method(:UpdateCarState));
        }
    }

    function UpdateCarState() {
        var state = mStarlineClient.GetCarState();
        if (state.StatusCode != 200){
            AppState = ERROR_RESPONSE;
        }
        else {
            AppState = IDLE;
        }

        WatchUi.requestUpdate(); 
    }

    function GetCarState() as CarState {
        return mStarlineClient.GetCarState();
    }

    function UpdateCredentials() {
        mLogin = Application.Properties.getValue("starline_API_user");
        mPass = Application.Properties.getValue("starline_API_pass");
        mUrl = Application.Properties.getValue("starline_API_URL");
        
        mStarlineClient.RefreshCredentials(mLogin, mPass, mUrl);
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

    // Handle timing out after exit
    function onExit() {
        System.exit();
    }

}