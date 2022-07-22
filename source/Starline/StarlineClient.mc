using Toybox.StringUtil;
using Toybox.Cryptography;

class StarlineClient{
    var mLogin as String;
    var mPass as String;
    var mUrl as String;
    var mAppId as String;
    var mAppSecret as String;
    var mIsAuth as Boolean;
    var mCarState as CarState;

    var mCode as String;
    var mCodeDate as Long;
    var mRefreshCarState_callback;

    function initialize() {
        mIsAuth = Application.Properties.getValue("starline_API_is_auth");
        mCarState = new CarState();
        mAppId = Application.Properties.getValue("starline_API_ID");
        mAppSecret = Application.Properties.getValue("starline_API_SECRET");
    }

    function RefreshCredentials(login as String, pass as String, url as String) {
        mLogin = login;
        mPass = pass;
        mUrl = url;
    }

    function Auth() as Boolean{
        GetCode();
    }
    
    function string_to_byte(string) {
		var options = {
			:fromRepresentation => StringUtil.REPRESENTATION_STRING_PLAIN_TEXT,
			:toRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
		};
		return StringUtil.convertEncodedString(string, options);
	}
    function byte_to_hexstring(byte) {
		var options = {
			:fromRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
			:toRepresentation => StringUtil.REPRESENTATION_STRING_HEX,
		};
		return StringUtil.convertEncodedString(byte, options);
	}

    function GetMD5(text) as String{
        var hasher = new Cryptography.Hash({:algorithm => Cryptography.HASH_MD5});
        hasher.update(string_to_byte(text));
        var hash_byte = hasher.digest();

        return byte_to_hexstring(hash_byte);
    }
    // Время жизни 1 час
    function GetCode() {
        var mCode = GetCacheProperty("starline_API_mCode", "starline_API_mCodeDate", 10 * 60 );
        if (mCode != null)
        {
            System.println("Use Properties Code");
            GetToken();
        }
        // Получаем новый код
        System.println("Getting new code");
        
        var secret = GetMD5(mAppSecret);
        var params = {                                              // set the parameters
            "appId" => mAppId,
            "secret" => secret
        };

        var url = mUrl + "/apiV3/application/getCode";

        var options = {                                             // set the options
            :method => Communications.HTTP_REQUEST_METHOD_GET,      // set HTTP method
            :headers => {                                           // set headers
            "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED},
            // set response type
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        var responseCallback = method(:onReceiveGetCode);                  // set responseCallback to
        // onReceive() method
        // Make the Communications.makeWebRequest() call
        //Communications.makeWebRequest(url, parameters, options, responseCallback)
        Communications.makeWebRequest(url, params, options, method(:onReceiveGetCode));
    }

     function onReceiveGetCode(responseCode as Number, data as Dictionary?) as Void {

        if (responseCode == 200) {
            System.println("Request Successful"); 
            var states = data.get("state");
            if (states == 1)
            {    
                var app_code = data.get("desc").get("code");
                if (app_code != null){
                    System.println("Got new app code: " + app_code); 
                    mCode = app_code;
                    mCodeDate = GetDataToLong();
                    SetCacheProperty("starline_API_mCode", "starline_API_mCodeDate", mCode );
                    return GetToken(); 
                }
            }
                            
        } else {
            mCarState.StatusCode = responseCode;
            System.println("Response: " + responseCode);            // print response code
            mRefreshCarState_callback.invoke();
            return;
        }

        mCarState.StatusCode = 500;
        System.println("Error parse response");            // print response code
        mRefreshCarState_callback.invoke();
        
    } 

    // Время жизни 4 часа
    function GetToken() {
        mRefreshCarState_callback.invoke();
    }

    // Время жизни 24 часа
    function GetSlId() {
        
    }

    function SetAuthbySlId() {
        
    }

    function GetDataToLong() as Number {
        // var now = new Time.Moment(Time.now().value());
        return Time.now().value();
    }

    function CheckAuth() as Boolean {
        if (!mIsAuth)
        {
            return Auth();
        }

        return true;
    }

    function GetCarState() as CarState {
        return mCarState;
    }

    function RefreshCarState(refresh_callback) {
        mRefreshCarState_callback = refresh_callback;
        if (CheckAuth()){
            // Запрос на обновление
        }
    }

    function GetCacheProperty(name_property, date_property, sec as Number) {
        var mProperyDate = Application.Properties.getValue(date_property);
        var mPropery = Application.Properties.getValue(name_property);
        var current_time = GetDataToLong();
        if ((current_time - sec) < mProperyDate)
        {
            System.println("Use properties cache");
            return mPropery;
        }

        return null;
    }

    function SetCacheProperty(name_property, date_property, value) {
        var current_time = GetDataToLong();
        Application.Properties.setValue(name_property, value);
        Application.Properties.setValue(date_property, current_time);
    }
}