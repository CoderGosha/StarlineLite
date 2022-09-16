using Toybox.WatchUi;

class CarMapDelegate extends WatchUi.BehaviorDelegate {

    var mView;

    function initialize(view) {
        BehaviorDelegate.initialize();
        mView = view;
    }

    function onBack() {
        // if current mode is preview mode them pop the view
        if(mView.getMapMode() == WatchUi.MAP_MODE_PREVIEW) {
            WatchUi.popView(WatchUi.SLIDE_UP);
        } else {
            // if browse mode change the mode to preview
            mView.setMapMode(WatchUi.MAP_MODE_PREVIEW);
        }
        return true;
    }

    function onSelect() {
        // on enter button press chenage the map view to browse mode
        mView.setMapMode(WatchUi.MAP_MODE_BROWSE);
        return true;
    }
}