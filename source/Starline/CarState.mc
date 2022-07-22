using Toybox.Time.Gregorian;

public enum LockStatus{
    Undefined = "Undefined",
    Lock = "Lock",
    Unlock = "Unlock"
}

public class CarState
{
    public var LockStatus as LockStatus;
    public var CarName as String;
    public var StatusCode as Integers; 
    public var DeviceId as String;
    public var TempEngine as String;
    public var TempInside as String;
    public var TimeUpdate as Number; 

    function initialize() {
        LockStatus = Undefined;        
        CarName = Application.Properties.getValue("starline_car_name");
        StatusCode = 0;
        TimeUpdate = 0;
    }

    function GetUpdateTime() as String {
        var today = Gregorian.info(TimeUpdate, Time.FORMAT_MEDIUM);
        var dateString = Lang.format(
            "$1$:$2$",
            [
                today.hour,
                today.min
            ]
        );

        return dateString;
    }

    function SetProperty(property as Dictionary) {
            StatusCode = 200;
            TimeUpdate = Time.now();

            CarName = property.get("alias");
            TempInside = property.get("ctemp");
            TempEngine = property.get("etemp");
            Application.Properties.setValue("starline_car_name", CarName);

            var car_state = property.get("car_state");
            if (car_state != null){
                var car_arm = car_state.get("arm") as Boolean;
                if (car_arm){
                    LockStatus = Lock;  
                }
                else {
                    LockStatus = Unlock;
                }
            }
    }
}