import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class StarlineLiteApp extends Application.AppBase {

    var controller;

    function initialize() {
        AppBase.initialize();
        controller = new $.StarlineController();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        return [ new StarlineLiteView(), new StarlineLiteDelegate() ] as Array<Views or InputDelegates>;
    }

}

function getApp() as StarlineLiteApp {
    return Application.getApp() as StarlineLiteApp;
}