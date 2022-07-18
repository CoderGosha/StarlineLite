import Toybox.Lang;
import Toybox.WatchUi;

class StarlineLiteDelegate extends WatchUi.BehaviorDelegate {

    var mController;

    function initialize() {
        BehaviorDelegate.initialize();
        mController = Application.getApp().controller;
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new MainMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

}