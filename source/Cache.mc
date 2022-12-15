
module CacheModule{
    var mUseCache = false;
    var mApplication;
    function FakeInit(useCache as Boolean, Application) {
        mUseCache = useCache;
        mApplication = Application;

    }
    function GetCacheProperty(name_property) {
        if (!mUseCache)
        {
            WebLoggerModule.webLogger.Log(LogDebug, "Skip properties cache " + name_property); 
            return null;
        }
        try {
            var mPropery = mApplication.Properties.getValue(name_property) as String;
            WebLoggerModule.webLogger.Log(LogDebug, "Use properties cache: " + name_property + ":" + mPropery);
            return mPropery;
        }
        catch( ex ) {
            WebLoggerModule.webLogger.Log(LogDebug,"Error read properties: " + name_property);
            return null;
        }

        return null;
    }

     function GetCachePropertyWithTime(name_property, date_property, sec as Number) {
        if (!mUseCache)
        {
            WebLoggerModule.webLogger.Log(LogDebug, "Skip properties cache " + name_property + ":" + date_property); 
            return null;
        }
        try {
            var mProperyDate = mApplication.Properties.getValue(date_property) as Number;
            var mPropery = mApplication.Properties.getValue(name_property) as String;
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

    function SetCachePropertyWithTime(name_property, date_property, value, sec as Number) {
        if (!mUseCache)
        {
            return;
        }

        var current_time = GetDataToLong() + sec;
        mApplication.Properties.setValue(name_property as String, value);
        mApplication.Properties.setValue(date_property as Number, current_time);
    }

    function SetCacheProperty(name_property, value) {
        if (!mUseCache)
        {
            return;
        }
        WebLoggerModule.webLogger.Log(LogDebug, "Set cache:" + name_property + " value: " + value);
        mApplication.Properties.setValue(name_property as String, value);
    }

    function GetAuthError() {
        return mLastError;
    }
}