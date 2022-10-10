using Toybox.Timer;
using Toybox.Application;
using Toybox.WatchUi;

using Toybox.WatchUi;
using Toybox.System;

public enum AppState {
    IDLE = "IDLE",
    SEND_COMMAND = "SEND_COMMAND",
    UPDATING = "UPDATING",
    NULL_CREDENTIAL = "NULL_CREDENTIAL",
    ERROR_RESPONSE = "ERROR_RESPONSE",
    NULL_API_KEY_OR_ID= "NULL_API_KEY_OR_ID",
    ERROR_PROXY_RESPONSE = "ERROR_PROXY_RESPONSE",
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
    var mAppId as String;
    var mAppSecret as String;
     var mLastError as String;

    // Initialize the controller
    function initialize() {
        // Allocate a timer
        mTimer = null;
        AppState = IDLE;
        mCarState = new CarState();
        mStarlineClient = new StarlineClient();
        //mAppState = AppState.IDLE;
        Application.Properties.setValue("initialization", true);
        mLastError = "Empty error";

    }

    function SendCommand(command as StarlineCommand) {
        AppState = SEND_COMMAND;
        mStarlineClient.SendCommand(method(:UpdateCarState), command);
    }

    function RefreshCarState() 
    {
        try {
            mLastError.toNumber();
            if (((AppState == IDLE) || (AppState == ERROR_RESPONSE)) && (CheckAccess()))
            {
                AppState = UPDATING;
                mStarlineClient.RefreshCarState(method(:UpdateCarState));
            }
        }
        catch( ex ) {
            AppState = ERROR_RESPONSE;
            mLastError = ex.getErrorMessage();
            WatchUi.requestUpdate(); 
        }
    }

    function GetError() {
        return mLastError;
    }

    function UpdateCarState() {
        var authStatus = mStarlineClient.GetAuthState();
        if (authStatus != Ready){
            if (authStatus == InvalidLoginOrPass){
                 AppState = NULL_CREDENTIAL;
            }

            if (authStatus == InvalidAPPIdORAPPSecret){
                 AppState = NULL_API_KEY_OR_ID;
            }

           if (authStatus == ErrorProxy){
                 AppState = ERROR_PROXY_RESPONSE;
            }
        }
        else {
            var state = mStarlineClient.GetCarState();
            if (state.StatusCode != 200){
                AppState = ERROR_RESPONSE;
            }
            else {
                AppState = IDLE;
            }
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
        mAppId = Application.Properties.getValue("starline_API_ID");
        mAppSecret = Application.Properties.getValue("starline_API_SECRET");
        mStarlineClient.RefreshCredentials(mLogin, mPass, mUrl);
    }

    function GoToCar() {
        var state = mStarlineClient.GetCarState();
        var position_car = state.position_car;
        return true;
    }

    function CheckAccess() as Boolean
    {
        UpdateCredentials();
        
        if ((mLogin.hashCode() == "".hashCode()) 
        || (mPass.hashCode() == "".hashCode())){
            AppState = NULL_CREDENTIAL;
            return false;
        }

        if ((mAppId.hashCode() == "".hashCode()) 
        || (mAppSecret.hashCode() == "".hashCode())){
            AppState = NULL_API_KEY_OR_ID;
            return false;
        }

        return true;
    }

    // Handle timing out after exit
    function onExit() {
        System.exit();
    }

}