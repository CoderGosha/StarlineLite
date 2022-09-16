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
        System.println(item.getId());
        var labelId = item.getId();

        if (labelId == :about)
        {
            WatchUi.pushView(new Rez.Layouts.MenuAbout(), new MenuAboutDelegat(), WatchUi.SLIDE_UP);
            return true;
        }
        else if (labelId == :lock)
        {
            mController.SendCommand(CommandLock);
            onBack();
            return true;
        }
        else if (labelId == :unlock)
        {
            mController.SendCommand(CommandUnlock);
            onBack();
            return true;
        }
        else if (labelId == :gocar)
        {
            mController.GoToCar();
            onBack();
            return true;
        }
        else if (labelId == :refresh)
        {
            mController.RefreshCarState();
            // progressBar = new WatchUi.ProgressBar(
            //     "Processing...",
            //     null
            // );
            //WatchUi.pushView(progressBar, new MenuProgressDelegate(), WatchUi.SLIDE_DOWN);
            onBack();
            return true;
        }
        return true;
    }

}