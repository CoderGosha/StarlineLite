
class StarlineClient{
    var mLogin as String;
    var mPass as String;
    var mUrl as String;
    var mIsAuth as Boolean;
    var mCarState as CarState;

    function initialize() {
        mIsAuth = Application.Properties.getValue("starline_API_is_auth");
        mCarState = new CarState();
    }

    function RefreshCredentials(login as String, pass as String, url as String) {
        mLogin = login;
        mPass = pass;
        mUrl = url;
    }

    function Auth() as Boolean{
        mCarState.StatusCode = 403;
    }

    function CheckAuth() as Boolean {
        if (!mIsAuth)
        {
            return Auth();
        }

        return true;
    }

    function GetCarState() as CarState {
        if (CheckAuth()){
            // Запрос на обновление
        }
        return mCarState;
    }
}