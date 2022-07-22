

class StarlineAuthService{
    var mLogin as String;
    var mPass as String;
    var mUrl as String;
    var mAppId as String;
    var mAppSecret as String;
    var mIsAuth as Boolean;


    var mCode as String;
    var mToken as String;
    var mSlid as String;
    var mUserId as String;
    var mSlnet as String;
    var mSlnetDate as Number;

    var mAuth_callback;

    function initialize() {
        mIsAuth = Application.Properties.getValue("starline_API_is_auth");
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
    
    function GetSlnet(auth_callback) as String {
        mAuth_callback = auth_callback;
        
        var current_time = GetDataToLong();

        if ((mSlnetDate != 0) && (mSlnet != null) && (current_time < (mSlnetDate - 10 * 60)))
        {
            System.println("Use properties token");
            return mSlnet; 
        }

        mSlnet = GetCacheProperty("starline_API_mSlnet", "starline_API_mSlnetDate", 10 * 60 );
        mSlnetDate = Application.Properties.getValue("starline_API_mSlnetDate");

        if (mSlnet != null)
        {
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

        return GetCacheProperty("starline_API_mUserId", "starline_API_mUserIdDate", 10 * 60 );
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

    function GetSHA1(text) as String{
        var hasher = new Cryptography.Hash({:algorithm => Cryptography.HASH_SHA1});
        hasher.update(string_to_byte(text));
        var hash_byte = hasher.digest();

        return byte_to_hexstring(hash_byte);
    }
    // Время жизни 1 час
    function GetCode() {
        mCode = GetCacheProperty("starline_API_mCode", "starline_API_mCodeDate", 10 * 60 );
        if (mCode != null)
        {
            System.println("Use Properties Code");
            return GetToken();
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
                    SetCacheProperty("starline_API_mCode", "starline_API_mCodeDate", mCode, 1 * 60 * 60);
                    return GetToken(); 
                }
            }
                            
        } else {
            mCarState.StatusCode = responseCode;
            System.println("Response: " + responseCode);            // print response code
            return;
        }

        mCarState.StatusCode = 500;
        System.println("Error parse response");            // print response code
        
    } 

    // Время жизни 4 часа
    function GetToken() {
        mToken = GetCacheProperty("starline_API_mToken", "starline_API_mTokenDate", 10 * 60 );
        if (mToken != null)
        {
            System.println("Use properties token");
            return GetSlId();
        }

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
                var token = data.get("desc").get("token");
                if (token != null){
                    System.println("Got new token: " + token); 
                    mToken = token;
                    SetCacheProperty("starline_API_mToken", "starline_API_mTokenDate", mToken, 4 * 60 * 60);
                    return GetSlId(); 
                }
            }
                            
        } else {
            mCarState.StatusCode = responseCode;
            System.println("Response: " + responseCode);            // print response code
            return;
        }

        mCarState.StatusCode = 500;
        System.println("Error parse response" + data);            // print response code
        
    } 

    // Время жизни - часа
    function GetSlId() {
        mSlid = GetCacheProperty("starline_API_mSlId", "starline_API_mSlIdDate", 10 * 60 );
        if (mSlid != null)
        {
            System.println("Use properties token");
            return GetSlnetToken();
        }

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
                var slid = data.get("desc").get("user_token");
                var userId = data.get("desc").get("id");
                if (slid != null){
                    System.println("Got new slid: " + slid); 
                    mSlid = slid;
                    mUserId = userId;
                    SetCacheProperty("starline_API_mSlId", "starline_API_mSlIdDate", slid, 1 * 60 * 60);
                    SetCacheProperty("starline_API_mUserId", "starline_API_mUserIdDate", mUserId, 1 * 60 * 60);
                    return GetSlnetToken();
                }
            }
                            
        } else {
            mCarState.StatusCode = responseCode;
            System.println("Response: " + responseCode + ":" + data);            // print response code
            return;
        }

        mCarState.StatusCode = 500;
        System.println("Error parse response" + data);            // print response code
        
    } 

    // Время 24 жизни - часа
    function GetSlnetToken() {
        mSlnet = GetCacheProperty("starline_API_mSlnet", "starline_API_mSlnetDate", 10 * 60 );
        if (mSlnet != null)
        {
            System.println("Use properties token");
            mAuth_callback.invoke();
        }

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
                mSlnet = data.get("nchan_id");
                mSlnetDate = GetDataToLong() + 24 * 60 * 60;
                SetCacheProperty("starline_API_mSlnet", "starline_API_mSlnetDate", mSlnet, 24 * 60 * 60);
                System.println("Response new slnet code: " + mSlnet);
                mAuth_callback.invoke();
                return;
            }

                            
        } else {
            mCarState.StatusCode = responseCode;
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
        var current_time = GetDataToLong();
        Application.Properties.setValue(name_property, value);
        Application.Properties.setValue(date_property, current_time + sec);
    }
}