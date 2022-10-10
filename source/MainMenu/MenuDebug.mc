import Toybox.Graphics;
import Toybox.WatchUi;

class MenuDebug extends WatchUi.View {
    var mController;
    var mLabelTitle;
    
    function initialize() {
        View.initialize();
        mController = Application.getApp().controller;
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MenuDebugLayout(dc));
        mLabelTitle = View.findDrawableById("labelDebug");
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
       var text = mController.GetError();
       mLabelTitle.setText(text);
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {

    }

}
