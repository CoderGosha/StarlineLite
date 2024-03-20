import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class MenuProgressDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() {
        return true;
    }
}

class MainMenuDelegate extends WatchUi.Menu2InputDelegate {
    var mController;
    var progressBar;

    function initialize() {
         Menu2InputDelegate.initialize();
         mController = Application.getApp().controller;
    }

    function onSelect(item) {
        WebLoggerModule.webLogger.Log(LogDebug,item.getId());
        var labelId = item.getId();

        if (labelId == :about)
        {
            WatchUi.pushView(new MenuAbout(), new MenuAboutDelegat(), WatchUi.SLIDE_UP);
        }
        else if (labelId == :debug)
        {
            WatchUi.pushView(new MenuDebug(), new MenuDebugDelegat(), WatchUi.SLIDE_UP);
        }
        else if (labelId == :lock)
        {
            mController.SendCommand(CommandLock);
            onBack();
        }
        else if (labelId == :unlock)
        {
            mController.SendCommand(CommandUnlock);
            onBack();
        }
        else if (labelId == :remote_start)
        {
            mController.SendCommand(CommandRemoteStart);
            onBack();
        }
        else if (labelId == :stop)
        {
            mController.SendCommand(CommandStop);
            onBack();
        }
        else if (labelId == :refresh)
        {
            mController.RefreshCarState();
            onBack();
        }

        else if (labelId == :sync_logs)
        {
            mController.SyncLog();
            onBack();
        }
    }

}