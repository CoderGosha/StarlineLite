using Toybox.Timer;
using Toybox.Application;
using Toybox.WatchUi;

using Toybox.WatchUi;
using Toybox.System;
using Toybox.Lang;



public enum AppState {
    IDLE = 1,
    SEND_COMMAND = 2,
    UPDATING = 3,
    NULL_CREDENTIAL = 4,
    ERROR_RESPONSE = 5,
    NULL_API_KEY_OR_ID= 6,
    ERROR_PROXY_RESPONSE = 7,
    NETWORK_ERROR = 8,
    UNINIT = 9,
}

class StarlineController
{
    public var appState as AppState;

    var mTimer;
    var mCarState as CarState;
    var mLogin as Lang.String or Null;
    var mPass as Lang.String or Null;
    var mUrl as Lang.String or Null;
    var mStarlineClient as StarlineClient;
    var mAppId as Lang.String or Null;
    var mAppSecret as Lang.String or Null;
    var mLastError as Lang.String;
    var backgroundUpdateProcess as Lang.Boolean;
    var backgroundUpdateProcessTimer as Timer.Timer;

    // Initialize the controller
    function initialize() {
        // Allocate a timer
        WebLoggerModule.webLogger = new WebLoggerModule.WebLogger();
        WebLoggerModule.webLogger.Log(LogDebug, "Starting App");
        mTimer = null;
        appState = UNINIT;
        mCarState = new CarState();
        mStarlineClient = new StarlineClient();
        Application.Properties.setValue("initialization", true);
        mLastError = "Empty error";
        backgroundUpdateProcess = false;
        backgroundUpdateProcessTimer = new Timer.Timer();
        backgroundUpdateProcessTimer.start(method(:UpdateCarStateBackground), 30000, true);
        RefreshCarState();
        CheckNetWork();
    }

    function CheckNetWork() {
        var isConnected = System.getDeviceSettings().connectionAvailable;
        if (!isConnected){
            appState = NETWORK_ERROR;
        }
        
    }

    function SendCommand(command) {
        appState = SEND_COMMAND;
        mStarlineClient.SendCommand(method(:UpdateAppState), command);
    }

    function RefreshCarState() 
    {
        if (appState == NETWORK_ERROR) {
            return;
        }
        
        if (CredentialsIsNull()){
            WatchUi.requestUpdate();
            return;
        }

        try {
            if ((appState == IDLE) || (appState == ERROR_RESPONSE) || (appState == UNINIT))
            {
                appState = UPDATING;
                mStarlineClient.RefreshCarState(method(:UpdateAppState));
            }
        }
        catch( ex ) {
            appState = ERROR_RESPONSE;
            mLastError = ex.getErrorMessage();
            WatchUi.requestUpdate(); 
        }
    }

    function GetError() {
        
        return mLastError;
    }

    function UpdateAppState() {
        var authStatus = mStarlineClient.GetAuthState();
        var authError = mStarlineClient.GetAuthError();

        if (authStatus != Ready){
            if (authStatus == InvalidLoginOrPass){
                 appState = NULL_CREDENTIAL;
                 mLastError = authError;
            }

            if (authStatus == InvalidAPPIdORAPPSecret){
                 appState = NULL_API_KEY_OR_ID;
                 mLastError = authError;
            }

           if (authStatus == ErrorProxy){
                 appState = ERROR_PROXY_RESPONSE;
                 mLastError = authError;
            }
        }
        else {
            var state = mStarlineClient.GetCarState();
            if (state.StatusCode != 200){
                appState = ERROR_RESPONSE;
            }
            else {
                appState = IDLE;
            }
        }

        WatchUi.requestUpdate(); 
    }

    function UpdateCarStateBackground() as Void
    {
        if (backgroundUpdateProcess){
            return;
        }

        try {
            backgroundUpdateProcess = true;
            RefreshCarState();
        }
        catch( ex ) {
            WebLoggerModule.webLogger.Log(LogError, "Error background update: " + ex.getErrorMessage());
            WatchUi.requestUpdate(); 
        }
        finally
        {
            backgroundUpdateProcess = false;
        }
    }

    // function UpdateCarStateBackgroundCallBack() {
    //     var state = mStarlineClient.GetCarState();
    //      if (state.StatusCode == 200){
    //         WatchUi.requestUpdate(); 
    //      }
    // }

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

    // function GoToCar() {
    //     var state = mStarlineClient.GetCarState();
    //     var position_car = state.position_car;
    //     return true;
    // }

    function SyncLog() {
        WebLoggerModule.webLogger.Log(LogInfo, "Start SyncLogs");
        WebLoggerModule.webLogger.SyncLogs();
        return true;
    }

    function CredentialsIsNull() as Lang.Boolean
    {
        UpdateCredentials();
        
        if ((mLogin.hashCode() == "".hashCode()) 
        || (mPass.hashCode() == "".hashCode())){
            appState = NULL_CREDENTIAL;
            mLastError = "Empty settings";
            WebLoggerModule.webLogger.Log(LogError, "NULL_CREDENTIAL");
            return true;
        }

        if ((mAppId.hashCode() == "".hashCode()) 
        || (mAppSecret.hashCode() == "".hashCode())){
            appState = NULL_API_KEY_OR_ID;
            mLastError = "Empty settings";
            WebLoggerModule.webLogger.Log(LogError, "NULL_API_KEY_OR_ID");
            return true;
        }

        return false;
    }

    // Handle timing out after exit
    function onExit() {
        System.exit();
    }

}