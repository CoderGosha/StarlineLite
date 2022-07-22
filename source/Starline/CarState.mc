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
    public var TempData as String;

    function initialize() {
        LockStatus = Undefined;        
        CarName = Application.Properties.getValue("starline_car_name");
        StatusCode = 0;
        TempData = "";
    }
}