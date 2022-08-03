using Toybox.StringUtil;
using Toybox.Cryptography;

public enum StralineCommand{
    CommandLock = "CommanLock",
    CommandUnlock = "CommandUnlock"
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
        // У нас точно есть токен - поэтому выполянем 
        var token = mAuthService.GetSlnet(method(:OnRefreshCarState));
        var userId = mAuthService.GetUserId();
        //var mSlid = mAuthService.mSlid;

       // mAuthService.TestSlid(mCarState.DeviceId);
        token = "4113D15950DE96AE90F877C6AC8027DF";
        var slnet = "slnet="+ token;

        //var url = "https://developer.starline.ru/json/v3/user/" + userId +"/data";
        var url = "https://developer.starline.ru/json/v2/user/"+ userId +"/user_info";
        var options = {                                             // set the options
            :method => Communications.HTTP_REQUEST_METHOD_GET,      // set HTTP method
            :headers => {                                           // set headers
             "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
             "Cookie"=>  slnet
             //"Digest" => mSlid,
             //"DigestAuth"=>  "true" 
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
            System.println("Request Successful"); 
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
            System.println("Response: " + responseCode + ":" + data);            // print response code
            mRefreshCarState_callback.invoke();
            return;
        }

        mCarState.StatusCode = 500;
        System.println("Error parse response" + data);            // print response code
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
            default:
                System.println("Unknown command");
                return null;
            }
    }

    function OnSendCommand(command) {
        // У нас точно есть токен - поэтому выполянем 
        var token = mAuthService.GetSlnet(method(:OnSendCommand));
        var deviceId = mCarState.DeviceId;
        token = "4113D15950DE96AE90F877C6AC8027DF";
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
            System.println("Request Successful"); 
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
            System.println("Response: " + responseCode + ":" + data);            // print response code
            mCommand_callback.invoke();
            return;
        }

        mCarState.StatusCode = 500;
        System.println("Error parse response" + data);            // print response code
        mCommand_callback.invoke();
    }
}