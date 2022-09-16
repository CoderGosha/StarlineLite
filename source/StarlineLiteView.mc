import Toybox.Graphics;
import Toybox.WatchUi;

class StarlineLiteView extends WatchUi.View {

    var mController;
    hidden var mLabelTitle;
    hidden var mLabelCarName;
    hidden var mLabelTemp;
    hidden var mLabelUpdate;

    function initialize() {
        View.initialize();
        mController = Application.getApp().controller;
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.LockLayout(dc));

        mLabelTitle = View.findDrawableById("labelTitle");
        mLabelTemp = View.findDrawableById("labelTemp");
        mLabelUpdate = View.findDrawableById("labelState");
        mLabelCarName = View.findDrawableById("labelCarName");
    
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
         mController.RefreshCarState();
    }
    
    function updateLabels(){
        var carState = mController.GetCarState();
        if (mController.AppState == NULL_CREDENTIAL)
        {
            mLabelTitle.setText("Check settings");
            mLabelTemp.setText("");
            mLabelUpdate.setText("Invalid credentials");
        }
        else if (mController.AppState == NULL_API_KEY_OR_ID)
        {
            mLabelTitle.setText("Check settings");
            mLabelTemp.setText("");
            mLabelUpdate.setText("Invalid APP Id");
        }
        else if (mController.AppState == ERROR_RESPONSE)
        {
            mLabelTitle.setText("Sync error");
            mLabelTemp.setText("");

            if (carState.StatusCode == 403){
                mLabelUpdate.setText("Auth error");
            }
            else{
                mLabelUpdate.setText(carState.ErrorMessage);
            }
            
        }
        else if (mController.AppState == UPDATING)
        {
            mLabelTitle.setText("Sync Starline");
            mLabelTemp.setText("");
            mLabelUpdate.setText("Synchronization...");
        }
        else if (mController.AppState == SEND_COMMAND)
        {
            // mLabelTitle.setText("Sync Starline");
            // mLabelTemp.setText("");
            mLabelUpdate.setText("Sending command...");
        }
        else {
            mLabelCarName.setText(carState.CarName);

            var tempData = "Inside:" + carState.TempInside + " | Engine: " + carState.TempEngine;

            mLabelTemp.setText(tempData);

            if (carState.LockStatus == Lock)
            {
                mLabelTitle.setText("Lock");
            } else if (carState.LockStatus == Unlock){
                mLabelTitle.setText("Unlock");
            }
            else{
                mLabelTitle.setText("Undefined");
            }

            mLabelUpdate.setText("Update: " + carState.GetUpdateTime());
        }
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        updateLabels();
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {

    }

}
