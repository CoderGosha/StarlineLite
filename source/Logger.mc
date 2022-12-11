public enum eWebLoggerLevel
{
    LogInfo = "LogInfo",
    LogError = "LogError",
    LogDebug = "LogDebug"
}


module WebLoggerModule
{
    class WebLogger{ 
        function Log(level as eWebLoggerLevel, message as String)
        {
            var log = level + ": " + message;
            System.println(log);
        }
    }
    var webLogger;
}

