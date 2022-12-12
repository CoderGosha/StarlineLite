using Toybox.Time.Gregorian;

public enum eWebLoggerLevel
{
    LogInfo = "LogInfo",
    LogError = "LogError",
    LogDebug = "LogDebug"
}


class LogRecord
{
    var mLevel as eWebLoggerLevel;
    var mMessage as String;
    var mDateTime as String;

    function initialize(level as eWebLoggerLevel, message as String) {
        var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        mLevel = level;
        mMessage = message;
        mDateTime = Lang.format(
            "$1$:$2$:$3$ $4$-$5$-$6$",
            [
                today.hour,
                today.min,
                today.sec,
                today.day,
                today.month,
                today.year
            ]
        );
    }
}

class LogArray{
    var mLogList;
    var mLogIndex as Intager;
    var mSize = 100;

    function initialize(){
        mLogList = new [mSize];
        mLogIndex = 0;
    }

    function AddLogMemory(log as LogRecord) {
        if (mLogIndex > mSize){
            mLogIndex = 0;
        }

        mLogList[mLogIndex] = log;
        mLogIndex = mLogIndex + 1;
    }

    function GetJson(){
        return "[]";
    }
}


module WebLoggerModule
{
    class WebLogger{ 
        var mProxyUrl as String;
        var mProxyUser as String;
        var mProxyPass as String;
        var mLogList as LogArray;

        function initialize() {
            mProxyUser = Application.Properties.getValue("starline_API_proxy_user");
            mProxyPass = Application.Properties.getValue("starline_API_proxy_pass");
            mProxyUrl = Application.Properties.getValue("starline_API_proxy_url");
            mLogList = new LogArray();
        }

        function Log(level as eWebLoggerLevel, message as String)
        {
            var log = level + ": " + message;
            System.println(log);

            var record = new LogRecord(level, message);
            mLogList.AddLogMemory(record);
        }

        function SyncLogs() {
            WebLoggerModule.webLogger.Log(LogDebug, "Syncing logs");
        
            var params = {                                              // set the parameters
                "app_name" => "StarlineLite",
                "request_id" => 1,
                "logs" => mLogList.GetJson()
            };

            var url = mProxyUrl + "/sync.logs";
            var authBasic =  "Basic " + StringUtil.encodeBase64(mProxyUser + ":" + mProxyPass);

            var options = {                                             // set the options
                :method => Communications.HTTP_REQUEST_METHOD_POST,      // set HTTP method
                :headers => {            
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                    "Authorization"  => authBasic},
                // set response type
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            };

            Communications.makeWebRequest(url, params, options, method(:onReceiveSyncLogs));
        }

        function onReceiveSyncLogs(responseCode as Number, data as Dictionary?) as Void {

            WebLoggerModule.webLogger.Log(LogDebug, "Response" + data);            // print response code
            
        } 
    }
    var webLogger;
}

