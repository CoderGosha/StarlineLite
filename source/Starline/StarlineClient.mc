using Toybox.StringUtil;
using Toybox.Cryptography;

public enum StralineCommand{
    CommandLock = "CommanLock",
    CommandUnlock = "CommandUnlock",
    CommandRemoteStart = "CommandRemoteStart",
    CommandStop = "CommandStop"
}

class StarlineClient
{
    var mCarState as CarState;
    var mAuthService as StarlineAuthService;
    var mRefreshCarState_callback;
    var mCommand_callback;

    function initialize() {
        mCarState = new CarState();
        mAuthService = new StarlineAuthService();
    }

    function GetCarState() as CarState {
        return mCarState;
    }

    function GetAuthState() as eAuthStatus {
        return mAuthService.AuthStatus;
    }
    function GetAuthError() as String {
        return mAuthService.GetAuthError();
    }
    function RefreshCarState(refresh_callback) {
        mRefreshCarState_callback = refresh_callback;
        var token = mAuthService.GetSlnet(method(:OnRefreshCarState));
        var userId = mAuthService.GetUserId();

        if (token == null){
            // Ожидаем что сработает колл бэк на этот метод
            return;
        }
        OnRefreshCarState();
    }

    function OnRefreshCarState() {
        if (mAuthService.AuthStatus != Ready)
            {
                FinalUpdate();
                return;
            }
        // У нас точно есть токен - поэтому выполянем 
        var token = mAuthService.GetSlnet(method(:OnRefreshCarState));
        var userId = mAuthService.GetUserId();
        var slnet = "slnet="+ token;

        //var url = "https://developer.starline.ru/json/v3/user/" + userId +"/data";
        var url = "https://developer.starline.ru/json/v2/user/"+ userId +"/user_info";
        var options = {                                             // set the options
            :method => Communications.HTTP_REQUEST_METHOD_GET,      // set HTTP method
            :headers => {                                           // set headers
             "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
             "Cookie"=>  slnet
              },
            // set response type
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        var responseCallback = method(:onReceiveGetUserData);                  // set responseCallback to
        // onReceive() method
        // Make the Communications.makeWebRequest() call
        //Communications.makeWebRequest(url, parameters, options, responseCallback)
        Communications.makeWebRequest(url, null, options, method(:onReceiveGetUserData));

    }

    function onReceiveGetUserData(responseCode as Number, data as Dictionary?) as Void {

        if (responseCode == 200) {
            WebLoggerModule.webLogger.Log(LogDebug,"Request Successful"); 
            var code = data.get("code");
            if (code.toNumber() == 200){
                var device = data.get("devices");
                if ((device != null) && (device.size() > 0)){
                    mCarState.SetProperty(device[0]);

                }
                mRefreshCarState_callback.invoke();
                return;
            }
            else{
                mCarState.ErrorMessage = data.get("codestring");
            }
                            
        } else {
            mCarState.StatusCode = responseCode;
            WebLoggerModule.webLogger.Log(LogDebug,"Response: " + responseCode + ":" + data);            // print response code
            mRefreshCarState_callback.invoke();
            return;
        }

        mCarState.StatusCode = 500;
        WebLoggerModule.webLogger.Log(LogDebug,"Error parse response" + data);            // print response code
        mRefreshCarState_callback.invoke();
    } 

    function RefreshCredentials(login as String, pass as String, url as String) {
        mAuthService.RefreshCredentials(login, pass, url);
    }

    function SendCommand(command_callback, command) {
        mCommand_callback = command_callback;
        if (mCarState.DeviceId == null)
        {
            return false;
        }

        OnSendCommand(command);
    }

    function FinalUpdate() {

        mRefreshCarState_callback.invoke();
    }

    function GetCommandParams(command as StralineCommand) {
        switch (command) {
            case CommandLock:
                return {                                             
                        "type" => "arm_start",
                        "arm_start" => 1
                        };
            case CommandUnlock:
                return {                                             
                        "type" => "arm_stop",
                        "arm_stop" => 1
                        };
            case CommandRemoteStart:
                return {                                             
                        "type" => "ign_start",
                        "ign_start" => 1
                        };
            case CommandStop:
                return {                                             
                        "type" => "ign_stop",
                        "ign_stop" => 1
                        };
            default:
                WebLoggerModule.webLogger.Log(LogDebug,"Unknown command");
                return null;
            }
    }

    function OnSendCommand(command) {
        // У нас точно есть токен - поэтому выполянем 
        var token = mAuthService.GetSlnet(method(:OnSendCommand));
        var deviceId = mCarState.DeviceId;
        var slnet = "slnet="+ token;

        //var url = "https://developer.starline.ru/json/v3/user/" + userId +"/data";
        var url = "https://developer.starline.ru/json/v1/device/" + deviceId + "/set_param";
        var options = {                                             // set the options
            :method => Communications.HTTP_REQUEST_METHOD_POST,      // set HTTP method
            :headers => {                                           // set headers
             "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
             "Cookie"=>  slnet },
            // set response type
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        var params = GetCommandParams(command);

        var responseCallback = method(:onReceiveSendCommand);                  // set responseCallback to
        // onReceive() method
        // Make the Communications.makeWebRequest() call
        //Communications.makeWebRequest(url, parameters, options, responseCallback)
        Communications.makeWebRequest(url, params, options, method(:onReceiveSendCommand));
    }

    function onReceiveSendCommand(responseCode as Number, data as Dictionary?) as Void {

        if (responseCode == 200) {
            WebLoggerModule.webLogger.Log(LogDebug,"Request Successful"); 
            var code = data.get("code");
            if (code.toNumber() == 200){
                mCarState.SetResultCommand(data);
                mCommand_callback.invoke();
                return;
            }
            else{
                mCarState.ErrorMessage = data.get("codestring");
            }
                            
        } else {
            mCarState.StatusCode = responseCode;
            WebLoggerModule.webLogger.Log(LogDebug,"Response: " + responseCode + ":" + data);            // print response code
            mCommand_callback.invoke();
            return;
        }

        mCarState.StatusCode = 500;
        WebLoggerModule.webLogger.Log(LogDebug,"Error parse response" + data);            // print response code
        mCommand_callback.invoke();
    }

}