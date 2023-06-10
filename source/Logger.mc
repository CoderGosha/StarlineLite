using Toybox.Time.Gregorian;
using Toybox.Lang;
using Toybox.Communications;

public enum eWebLoggerLevel
{
    LogInfo = "LogInfo",
    LogError = "LogError",
    LogDebug = "LogDebug"
}


class LogRecord
{
    var mLevel as eWebLoggerLevel;
    var mMessage as Lang.String;
    var mDateTime as Lang.String;

    function initialize(level as eWebLoggerLevel, message as Lang.String) {
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
    var mLogIndex = 0;
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
        var json =  "[";
        for (var i=0; i<mSize; i++){
            if (mLogList[i] != null){
                if (i != 0){
                    json += ",";
                }
                var record = mLogList[i];
                var msg = "{";
                msg +=  "\"level\"" + ":\"" + record.mLevel + "\",";
                msg +=  "\"dateTime\"" + ":\"" + record.mDateTime + "\",";
                msg +=  "\"message\"" + ":\"" + record.mMessage + "\"";

                msg += "}";
                json += msg;
            }
        }
        json +="]";
       // var dict = {"test" => [{"test"=>"value1"}, {}]}
        return StringUtil.encodeBase64(json);
    }
}


module WebLoggerModule
{
    class WebLogger{ 
        var mProxyUrl as Lang.String;
        var mProxyUser as Lang.String;
        var mProxyPass as Lang.String;
        var mLogList as LogArray;

        function initialize() {
            mProxyUser = Application.Properties.getValue("starline_API_proxy_user");
            mProxyPass = Application.Properties.getValue("starline_API_proxy_pass");
            mProxyUrl = Application.Properties.getValue("starline_API_proxy_url");
            mLogList = new LogArray();
        }

        function Log(level as eWebLoggerLevel, message as Lang.String)
        {
            var log = level + ": " + message;
            System.println(log);

            var record = new LogRecord(level, message);
            mLogList.AddLogMemory(record);
        }

        function onReceiveSyncLogs(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void{
            WebLoggerModule.webLogger.Log(LogDebug, "Response" + data);            // print response code
        } 

        function SyncLogs() as Void{
            var params = {                                              // set the parameters
                "app_name" => "StarlineLite",
                "request_id" => Time.now().value(),
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
    }
    var webLogger;
}

