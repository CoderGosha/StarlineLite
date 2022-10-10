

class StarlineAuthService{
    var mLogin as String;
    var mPass as String;
    var mUrl as String;
    var mAppId as String;
    var mAppSecret as String;
    var mIsAuth as Boolean;
    var mIsDirectAuth as Boolean;

    var mCode as String;
    var mToken as String;
    public var mSlid as String;
    var mUserId as String;
    var mSlnet as String;
    var mSlnetDate as Number;

    var mAuth_callback;

    var mProxyUrl as String;
    var mProxyKey as String;

    public var AuthStatus as eAuthStatus;

    function initialize() {
        mIsAuth = Application.Properties.getValue("starline_API_is_auth");
        mAppId = Application.Properties.getValue("starline_API_ID");
        mAppSecret = Application.Properties.getValue("starline_API_SECRET");
        mIsDirectAuth = Application.Properties.getValue("starline_API_is_direct_auth");
        mProxyUrl = Application.Properties.getValue("starline_API_proxy_url");
        mProxyKey = Application.Properties.getValue("starline_API_proxy_key");
        AuthStatus = AuthUndefined;
    }

    function RefreshCredentials(login as String, pass as String, url as String) {
        mLogin = login;
        mPass = pass;
        mUrl = url;
    }

    function Auth() as Boolean{
        GetCode();

    }
    
    function GetSlnet(auth_callback) as String {
        mAuth_callback = auth_callback;
        
        var current_time = GetDataToLong();

        if ((mSlnetDate != 0) && (mSlnet != null) && (current_time < (mSlnetDate - 10 * 60)))
        {
            AuthStatus = Ready;
            System.println("Use properties token");
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
    }

    function GetUserId() as string
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

    function GetMD5(text) as String{
        try {
            var hasher = new Cryptography.Hash({:algorithm => Cryptography.HASH_MD5});
            hasher.update(string_to_byte(text));
            var hash_byte = hasher.digest();

            return byte_to_hexstring(hash_byte);
        }
        catch( ex ) {
             FinalAuth(AuthUndefined);  
        }
  
    }

    function GetSHA1(text) as String{
        var hasher = new Cryptography.Hash({:algorithm => Cryptography.HASH_SHA1});
        hasher.update(string_to_byte(text));
        var hash_byte = hasher.digest();

        return byte_to_hexstring(hash_byte);
    }
    // Время жизни 1 час
    function GetCode() {
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
                var desc = data.get("desc");
                if (desc != null) {
                    var app_code = desc.get("code");
                    if (app_code != null){
                        System.println("Got new app code: " + app_code); 
                        mCode = app_code;
                        return GetToken(); 
                    }
                }
            }
                            
        } else {
        
            System.println("Response: " + responseCode);            // print response code
        }
       
        System.println("Error parse response");            // print response code
        FinalAuth(InvalidAPPIdORAPPSecret); 
        
    } 

    // Время жизни 4 часа
    function GetToken() {

        // Получаем новый код
        System.println("Getting new token");
        
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

    function onReceiveGetToken(responseCode as Number, data as Dictionary?) as Void {

        if (responseCode == 200) {
            System.println("Request Successful"); 
            var states = data.get("state");
            if (states == 1)
            {    
                var desc = data.get("desc");
                if (desc != null) {
                var token = desc.get("token");
                    if (token != null){
                        System.println("Got new token: " + token); 
                        mToken = token;
                        return GetSlId(); 
                    }
                }
            }
                            
        } else {
            System.println("Response: " + responseCode);            // print response code
        }

        System.println("Error parse response" + data);            // print response code
        FinalAuth(InvalidAPPIdORAPPSecret);  
    } 

    // Время жизни - часа
    function GetSlId() {

        // Получаем новый код
        System.println("Getting new slid");
        
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

    function onReceiveGetSlId(responseCode as Number, data as Dictionary?) as Void {

        if (responseCode == 200) {
            System.println("Request Successful"); 
            var states = data.get("state");
            if (states == 1)
            {    
                var desc = data.get("desc");
                if (desc != null) {
                var slid = desc.get("user_token");
                    if (slid != null){
                        System.println("Got new slid: " + slid); 
                        mSlid = slid;
                        return GetSlnetToken();
                    }
                }
            }
                            
        } else {
            System.println("Response: " + responseCode + ":" + data);            // print response code
        }

        System.println("Error parse response" + data);            // print response code
        FinalAuth(InvalidLoginOrPass);
    } 

    function FinalAuth(status) {
        AuthStatus = status;
        mAuth_callback.invoke();
    }

    // Время 24 жизни - часа
    function GetSlnetToken() {

        mSlnet = GetCacheProperty("starline_API_mSlnet", "starline_API_mSlnetDate", 10 * 60 );
        mUserId = GetCacheProperty("starline_API_mUserId", "starline_API_mUserIdDate", 10 * 60 );
        if ((mSlnet != null) && (mUserId != null))
        {
            System.println("Use properties token");
            FinalAuth(Ready);
        }

        if (mIsDirectAuth){
            GetSlnetTokenStarline();
        }

        else {
            GetSlnetTokenWithProxy();
        }
    }

    function GetSlnetTokenStarline() {

        // Получаем новый код
        System.println("Getting new slnet");
        
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

    function onReceiveGetSlnet(responseCode as Number, data as Dictionary?) as Void {

        if (responseCode == 200) {
            System.println("Request Successful"); 
            var code = data.get("code");
            if (code.toNumber() == 200){
                mSlnet = null; // data.get("nchan_id"); // Нужно брать из куков! 
                mSlnetDate = GetDataToLong() + 24 * 60 * 60;
                mUserId = data.get("user_id");
                SetCacheProperty("starline_API_mUserId", "starline_API_mUserIdDate", mUserId, 30 * 24 * 60 * 60);
                SetCacheProperty("starline_API_mSlnet", "starline_API_mSlnetDate", mSlnet, 24 * 60 * 60);
                System.println("Response new slnet code: " + mSlnet);
                mAuth_callback.invoke();
                return;
            }

                            
        } else {
           
            System.println("Response: " + responseCode + ":" + data);            // print response code
            return;
        }

        System.println("Error parse response" + data);            // print response code
        
    } 

    function GetSlnetTokenWithProxy() {
        // Получаем новый код
        System.println("Getting new slnet with proxy");
        //https://starlineauth.cg-bot.ru//auth.slid?slid_token=aa6ef6277ef77a3acc74c9f9de0d54a3:1458758
        var params = {                                              // set the parameters
            "slid_token" => mSlid
        };

        var url = mProxyUrl + "auth.slid";

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

    function onReceiveGetSlnetWithProxy(responseCode as Number, data as Dictionary?) as Void {
        //
        if (responseCode == 200) {
            System.println("Request Successful"); 

            mSlnet = data.get("slnet_token"); // Нужно брать из куков! 
            mSlnetDate = GetDataToLong() + 24 * 60 * 60;
            mUserId = data.get("user_id");
            SetCacheProperty("starline_API_mUserId", "starline_API_mUserIdDate", mUserId, 30 * 24 * 60 * 60);
            SetCacheProperty("starline_API_mSlnet", "starline_API_mSlnetDate", mSlnet, 24 * 60 * 60);
            System.println("Response new slnet code: " + mSlnet);  
            FinalAuth(Ready);         
            return;

                            
        } else {
           
            System.println("Response: " + responseCode + ":" + data);            // print response code
        }

        System.println("Error parse response" + data);            // print response code
        FinalAuth(ErrorProxy);
    } 

      function onReceiveTestSlid(responseCode as Number, data as Dictionary?) as Void {

        if (responseCode == 200) {
            System.println("Request Successful"); 
                            
        } else {
            System.println("Response: " + responseCode + ":" + data);            // print response code
            return;
        }

        mCarState.StatusCode = 500;
        System.println("Error parse response" + data);            // print response code
        
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



    function GetCacheProperty(name_property, date_property, sec as Number) {
        var mProperyDate = Application.Properties.getValue(date_property);
        var mPropery = Application.Properties.getValue(name_property);
        var current_time = GetDataToLong();
        if (mProperyDate == 0)
           {return null;}

        if (current_time < (mProperyDate - sec))
        {
            System.println("Use properties cache" + name_property + ":" + mPropery);
            return mPropery;
        }

        return null;
    }

    function SetCacheProperty(name_property, date_property, value, sec as Number) {
        var current_time = GetDataToLong() + sec;
        Application.Properties.setValue(name_property, value);
        Application.Properties.setValue(date_property, current_time);
    }
}