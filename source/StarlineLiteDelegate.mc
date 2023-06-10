import Toybox.Lang;
import Toybox.WatchUi;

class StarlineLiteDelegate extends WatchUi.BehaviorDelegate {

    var mController;

    function initialize() {
        BehaviorDelegate.initialize();
        mController = Application.getApp().controller;
    }

    // function onMenu() as Lang.Boolean {
    //     WatchUi.pushView(new Rez.Menus.MainMenu(), new MainMenuDelegate(), WatchUi.SLIDE_UP);
    //     return true;
    // }

    function onSelect() as Lang.Boolean{
        WatchUi.pushView(new Rez.Menus.MainMenu(), new MainMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

}