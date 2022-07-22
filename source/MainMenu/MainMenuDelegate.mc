import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class MainMenuDelegate extends WatchUi.Menu2InputDelegate {
    var mController;
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
            return true;
        }
        return true;
    }

}