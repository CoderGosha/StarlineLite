
using Toybox.Lang;

class StarlineAuthService{
    var mLogin as Lang.String or Null;
    var mPass as Lang.String or Null;
    var mUrl as Lang.String or Null;
    var mAppId as Lang.String;
    var mAppSecret as Lang.String;
    var mIsAuth as Lang.Boolean;
    var mIsDirectAuth as Lang.Boolean;

    var mCode as Lang.String or Null;
    var mToken as Lang.String or Null;
    public var mSlid as Lang.String or Null;
    var mUserId as Lang.String or Null;
    var mSlnet as Lang.String or Null;
    var mSlnetDate as Lang.Number or Null;

    var mAuth_callback;

    var mProxyUrl as Lang.String;
    var mLastError as Lang.String;
    var mUseCache as Lang.Boolean;

    public var AuthStatus as eAuthStatus;

    function initialize() {
        mIsAuth = Application.Properties.getValue("starline_API_is_auth");
        mAppId = Application.Properties.getValue("starline_API_ID");
        mAppSecret = Application.Properties.getValue("starline_API_SECRET");
        mIsDirectAuth = Application.Properties.getValue("starline_API_is_direct_auth");
        mProxyUrl = Application.Properties.getValue("starline_API_proxy_url");
        AuthStatus = AuthUndefined;
        mLastError = "Empty";
        mUseCache = true;
    }

    function RefreshCredentials(login as Lang.String, pass as Lang.String, url as Lang.String) {
        mLogin = login;
        mPass = pass;
        mUrl = url;
    }

    function Auth()
    {
        GetCode();
    }
    
    function GetSlnet(auth_callback) as Lang.String or Null{
        mAuth_callback = auth_callback;
        
        var current_time = GetDataToLong();

        if ((mSlnetDate != 0) && (mSlnet != null) && (current_time < (mSlnetDate - 10 * 60)))
        {
            AuthStatus = Ready;
            return mSlnet; 
        }

        mSlnet = GetCacheProperty("starline_API_mSlnet", "starline_API_mSlnetDate", 10 * 60 );
        mSlnetDate = Application.Properties.getValue("starline_API_mSlnetDate");
        var userId = GetUserId();

        if ((mSlnet != null) && (userId != null))
        {
            AuthStatus = Ready;
            return mSlnet;
        }

        GetCode();
        return null;
    }

    function GetUserId() as Lang.String
    {
        if (mUserId != null)
        {
            return mUserId;
        }

        mUserId = GetCacheProperty("starline_API_mUserId", "starline_API_mUserIdDate", 10 * 60 );
        return mUserId;
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

    function GetMD5(text) as Lang.String or Null{
        try {
            var hasher = new Cryptography.Hash({:algorithm => Cryptography.HASH_MD5});
            hasher.update(string_to_byte(text));
            var hash_byte = hasher.digest();

            return byte_to_hexstring(hash_byte);
        }
        catch( ex ) {
             FinalAuth(AuthUndefined);  
        }
        return null;
    }

    function GetSHA1(text) as Lang.String{
        var hasher = new Cryptography.Hash({:algorithm => Cryptography.HASH_SHA1});
        hasher.update(string_to_byte(text));
        var hash_byte = hasher.digest();

        return byte_to_hexstring(hash_byte);
    }
    // Время жизни 1 час
    function GetCode() {
        // Получаем новый код
        WebLoggerModule.webLogger.Log(LogDebug,"Getting new code");
        
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

     function onReceiveGetCode(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void{

        if (responseCode == 200) {
            WebLoggerModule.webLogger.Log(LogDebug,"Request Successful"); 
            var states = data.get("state");
            if (states == 1)
            {    
                var desc = data.get("desc") as Lang.Dictionary;
                if (desc != null) {
                    var app_code = desc.get("code") as Lang.String;
                    if (app_code != null){
                        WebLoggerModule.webLogger.Log(LogDebug,"Got new app code: " + app_code); 
                        mCode = app_code;
                        GetToken();
                        return; 
                    }
                }
            }
            else {
                mLastError = "InvalidAPPIdORAPPSecret: " + (data.get("desc") as Lang.Dictionary).get("message").toString();
            }
                            
        } else {
            mLastError = "InvalidAPPIdORAPPSecret. Response: " + responseCode;
            WebLoggerModule.webLogger.Log(LogDebug,"Response: " + responseCode);            // print response code
        }
       
        WebLoggerModule.webLogger.Log(LogDebug,"Error parse response");            // print response code
        FinalAuth(InvalidAPPIdORAPPSecret); 
        
    } 

    // Время жизни 4 часа
    function GetToken() {

        // Получаем новый код
        WebLoggerModule.webLogger.Log(LogDebug,"Getting new token");
        
        var secret = GetMD5(mAppSecret + mCode);
        var params = {                                              // set the parameters
            "appId" => mAppId,
            "secret" => secret
        };

        var url = mUrl + "/apiV3/application/getToken";

        var options = {                                             // set the options
            :method => Communications.HTTP_REQUEST_METHOD_GET,      // set HTTP method
            :headers => {                                           // set headers
            "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED},
            // set response type
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        var responseCallback = method(:onReceiveGetToken);                  // set responseCallback to
        // onReceive() method
        // Make the Communications.makeWebRequest() call
        //Communications.makeWebRequest(url, parameters, options, responseCallback)
        Communications.makeWebRequest(url, params, options, method(:onReceiveGetToken));
    }

    function onReceiveGetToken(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void{

        if (responseCode == 200) {
            WebLoggerModule.webLogger.Log(LogDebug,"Request Successful"); 
            var states = data.get("state");
            if (states == 1)
            {    
                var desc = data.get("desc") as Lang.Dictionary;
                if (desc != null) {
                var token = desc.get("token");
                    if (token != null){
                        WebLoggerModule.webLogger.Log(LogDebug,"Got new token: " + token); 
                        mToken = token.toString();
                        GetSlId(); 
                        return; 
                    }
                }
            }
            else {
                mLastError = "InvalidAPPIdORAPPSecret: " + (data.get("desc") as Lang.Dictionary).get("message").toString();
            }
                            
        } else {
            mLastError = "InvalidAPPIdORAPPSecret. Response: " + responseCode + ":" + data;
            WebLoggerModule.webLogger.Log(LogDebug,"Response: " + responseCode);            // print response code
        }

        WebLoggerModule.webLogger.Log(LogDebug,"Error parse response" + data);            // print response code
        FinalAuth(InvalidAPPIdORAPPSecret);  
    } 

    // Время жизни - часа
    function GetSlId() {

        // Получаем новый код
        WebLoggerModule.webLogger.Log(LogDebug,"Getting new slid");
        
        var secret = GetSHA1(mPass);
        var params = {                                              // set the parameters
            "login" => mLogin,
            "pass" => secret
        };

        var url = mUrl + "/apiV3/user/login/";

        var options = {                                             // set the options
            :method => Communications.HTTP_REQUEST_METHOD_POST,      // set HTTP method
            :headers => {                                           // set headers
           // "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
            "token"=> mToken },
            // set response type
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        var responseCallback = method(:onReceiveGetSlId);                  // set responseCallback to
        // onReceive() method
        // Make the Communications.makeWebRequest() call
        //Communications.makeWebRequest(url, parameters, options, responseCallback)
        Communications.makeWebRequest(url, params, options, method(:onReceiveGetSlId));
    }

    function onReceiveGetSlId(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void{

        if (responseCode == 200) {
            WebLoggerModule.webLogger.Log(LogDebug,"Request Successful"); 
            var states = data.get("state");
            if (states == 1)
            {    
                var desc = data.get("desc") as Lang.Dictionary;
                if (desc != null) {
                var slid = desc.get("user_token");
                    if (slid != null){
                        WebLoggerModule.webLogger.Log(LogDebug,"Got new slid: " + slid); 
                        mSlid = slid.toString();
                        GetSlnetToken();
                        return; 
                    }
                }
            }
            else {
                mLastError = "InvalidLoginOrPass: " + (data.get("desc") as Lang.Dictionary).get("message").toString();
            }
                            
        } else {
            mLastError = "InvalidLoginOrPass. Response: " + responseCode + ":" + data;
            WebLoggerModule.webLogger.Log(LogDebug,"Response: " + responseCode + ":" + data);            // print response code
        }

        WebLoggerModule.webLogger.Log(LogDebug,"Error parse response" + data);            // print response code
        FinalAuth(InvalidLoginOrPass);
    } 

    function FinalAuth(status) {
        AuthStatus = status;
        mAuth_callback.invoke();
    }

    // Время 24 жизни - часа
    function GetSlnetToken() {

        if ((mSlnet == null) || (mUserId == null)) 
        {
            mSlnet = GetCacheProperty("starline_API_mSlnet", "starline_API_mSlnetDate", 10 * 60 );
            mUserId = GetCacheProperty("starline_API_mUserId", "starline_API_mUserIdDate", 10 * 60 );
        }
        if ((mSlnet != null) && (mUserId != null))
        {
            WebLoggerModule.webLogger.Log(LogDebug,"Use properties token");
            FinalAuth(Ready);
        }

        // Тут когда то можно сделать выбор авторизации
        GetSlnetTokenWithProxy();
    }

    function GetSlnetTokenStarline() {

        // Получаем новый код
        WebLoggerModule.webLogger.Log(LogDebug,"Getting new slnet");
        
        var params = {                                              // set the parameters
            "slid_token" => mSlid
        };

        var url = "https://developer.starline.ru/json/v2/auth.slid";

        var options = {                                             // set the options
            :method => Communications.HTTP_REQUEST_METHOD_POST,      // set HTTP method
            :headers => {                                           // set headers
             "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON},
            // set response type
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        var responseCallback = method(:onReceiveGetSlnet);                  // set responseCallback to
        // onReceive() method
        // Make the Communications.makeWebRequest() call
        //Communications.makeWebRequest(url, parameters, options, responseCallback)
        Communications.makeWebRequest(url, params, options, method(:onReceiveGetSlnet));
    }

    function onReceiveGetSlnet(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void{

        if (responseCode == 200) {
            WebLoggerModule.webLogger.Log(LogDebug,"Request Successful"); 
            var code = data.get("code") as Lang.Number;
            if (code.toNumber() == 200){
                mSlnet = null; // data.get("nchan_id"); // Нужно брать из куков! 
                mSlnetDate = GetDataToLong() + 24 * 60 * 60;
                mUserId = data.get("user_id");
                SetCacheProperty("starline_API_mUserId", "starline_API_mUserIdDate", mUserId, 30 * 24 * 60 * 60);
                SetCacheProperty("starline_API_mSlnet", "starline_API_mSlnetDate", mSlnet, 24 * 60 * 60);
                WebLoggerModule.webLogger.Log(LogDebug,"Response new slnet code: " + mSlnet);
                mAuth_callback.invoke();
                return;
            }

                            
        } else {
           
            WebLoggerModule.webLogger.Log(LogDebug,"Response: " + responseCode + ":" + data);            // print response code
            return;
        }

        WebLoggerModule.webLogger.Log(LogDebug,"Error parse response" + data);            // print response code
        
    } 

    function GetSlnetTokenWithProxy() {
        // Получаем новый код
        WebLoggerModule.webLogger.Log(LogDebug,"Getting new slnet with proxy");
        //https://starlineauth.cg-bot.ru//auth.slid?slid_token=aa6ef6277ef77a3acc74c9f9de0d54a3:1458758
        var params = {                                              // set the parameters
            "slid_token" => mSlid
        };

        var url = mProxyUrl + "/auth.slid";

        var options = {                                             // set the options
            :method => Communications.HTTP_REQUEST_METHOD_GET,      // set HTTP method
            :headers => {                                           // set headers
             "Content-Type" => Communications.HTTP_RESPONSE_CONTENT_TYPE_URL_ENCODED},
            // set response type
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        var responseCallback = method(:onReceiveGetSlnetWithProxy);                  // set responseCallback to
        // onReceive() method
        // Make the Communications.makeWebRequest() call
        //Communications.makeWebRequest(url, parameters, options, responseCallback)
        Communications.makeWebRequest(url, params, options, method(:onReceiveGetSlnetWithProxy));
    }

    function onReceiveGetSlnetWithProxy(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void{
        //
        if (responseCode == 200) {
            WebLoggerModule.webLogger.Log(LogDebug,"Request Successful"); 

            mSlnet = data.get("slnet_token"); // Нужно брать из куков! 
            mSlnetDate = GetDataToLong() + 24 * 60 * 60;
            mUserId = data.get("user_id");
            SetCacheProperty("starline_API_mUserId", "starline_API_mUserIdDate", mUserId, 30 * 24 * 60 * 60);
            SetCacheProperty("starline_API_mSlnet", "starline_API_mSlnetDate", mSlnet, 24 * 60 * 60);
            WebLoggerModule.webLogger.Log(LogDebug,"Response new slnet code: " + mSlnet);  
            FinalAuth(Ready);         
            return;

                            
        } else {
           mLastError = "ErrorProxy. Response: " + responseCode + ":" + data;
            WebLoggerModule.webLogger.Log(LogDebug,"ErrorProxy. Response: " + responseCode + ":" + data);            // print response code
        }

        WebLoggerModule.webLogger.Log(LogDebug,"Error parse response" + data);            // print response code
        FinalAuth(ErrorProxy);
    } 

    function CheckAuth() as Lang.Boolean {
        if (!mIsAuth)
        {
            return Auth();
        }

        return true;
    }



    function GetCacheProperty(name_property, date_property, sec as Lang.Number) {
        if (!mUseCache)
        {
            WebLoggerModule.webLogger.Log(LogDebug, "Skip properties cache " + name_property + ":" + date_property); 
            return null;
        }
        try {
            var mProperyDate = Application.Properties.getValue(date_property) as Lang.Number;
            var mPropery = Application.Properties.getValue(name_property) as Lang.String;
            var current_time = GetDataToLong();
            if (mProperyDate == 0)
                {return null;}

            if (current_time < (mProperyDate - sec))
            {
                WebLoggerModule.webLogger.Log(LogDebug, "Use properties cache: " + name_property + ":" + mPropery);
                return mPropery;
            }
        }
        catch( ex ) {
            WebLoggerModule.webLogger.Log(LogDebug,"Error read properties: " + name_property);
            return null;
        }

        return null;
    }

    function SetCacheProperty(name_property, date_property, value, sec as Lang.Number) {
        if (!mUseCache)
        {
            return;
        }

        var current_time = GetDataToLong() + sec;
        Application.Properties.setValue(name_property as Lang.String, value);
        Application.Properties.setValue(date_property as Lang.Number, current_time);
    }

    function GetAuthError() {
        return mLastError;
    }
}