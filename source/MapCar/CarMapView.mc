using Toybox.WatchUi;

class CarMapView extends WatchUi.MapView {
    
    function initialize() {
        View.initialize();
    }

    // Resources are loaded here
    function onLayout(dc) {
        setLayout(Rez.Layouts.CarMap(dc));
    }

    // onShow() is called when this View is brought to the foreground
    function onShow() {
    }

    // onUpdate() is called periodically to update the View
    function onUpdate(dc) {
        View.onUpdate(dc);
    }

    // onHide() is called when this View is removed from the screen
    function onHide() {
    }
}