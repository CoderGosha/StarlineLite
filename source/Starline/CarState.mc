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

    function initialize() {
        LockStatus = Undefined;        
        CarName = Application.Properties.getValue("starline_car_name");
        StatusCode = 0;
    }
}