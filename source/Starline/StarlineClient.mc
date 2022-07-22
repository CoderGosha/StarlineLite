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

        var slnet = "slnet="+ token;

        var url = "https://developer.starline.ru/json/v3/user/" + userId +"/data";

        var options = {                                             // set the options
            :method => Communications.HTTP_REQUEST_METHOD_GET,      // set HTTP method
            :headers => {                                           // set headers
             "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
             "Cookie"=>  slnet },
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

                //mRefreshCarState_callback.invoke();
                return;
            }
                            
        } else {
            mCarState.StatusCode = responseCode;
            System.println("Response: " + responseCode + ":" + data);            // print response code
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

    }
}