using Toybox.Time.Gregorian;
using Toybox.Position;

public enum LockStatus{
    Undefined = "Undefined",
    Lock = "Lock",
    Unlock = "Unlock",
    RunAndUnlock = "RunAndUnlock",
    RunAndLock = "RunAndLock"
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
    public var ErrorMessage as String; 
    public var position_longitude = 0 as Float;
    public var position_latitude = 0 as Float;
    public var position_car;

    function initialize() {
        LockStatus = Undefined;        
        CarName = Application.Properties.getValue("starline_car_name");
        StatusCode = 0;
        TimeUpdate = 0;
        DeviceId = Application.Properties.getValue("starline_car_device_id");
        ErrorMessage = "";
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
            DeviceId = property.get("device_id");

            var car_state = property.get("car_state");
            if (car_state != null){
                var car_arm = car_state.get("arm") as Boolean;
                var car_run = car_state.get("run") as Boolean;
                SetLockState(car_arm, car_run);
            }

            var position = property.get("position");
            if (position != null){
                position_longitude = position.get("x") as Float;
                position_latitude = position.get("y") as Float;
                position_car = new Position.Location(
                    {
                        :latitude => position_latitude,
                        :longitude => position_longitude,
                        :format => :degrees
                    }
                 );
             }
            
            Application.Properties.setValue("starline_car_name", CarName);
            Application.Properties.setValue("starline_car_device_id", DeviceId);
    }

    function SetLockState(car_arm as Boolean, car_run as Boolean) {
        if (car_arm && car_run){
                    LockStatus = RunAndLock;  
                }
                else if (car_arm && !car_run){
                    LockStatus = Lock;  
                }
                else if (!car_arm && !car_run){
                    LockStatus = Unlock;  
                }

                else if (!car_arm && car_run){
                    LockStatus = RunAndUnlock;  
                }
                else {
                    LockStatus = Undefined;
                }
    }

    function SetResultCommand(property as Dictionary) {
        var car_arm = property.get("arm") as String;
        var car_run = property.get("run") as String;
        var car_arm_bool = false;
        var car_run_bool = false;

        if (car_arm.toNumber() == 1){
            car_arm_bool = true;
        }

        if (car_run.toNumber() == 1){
            car_run_bool = true;
        }

        SetLockState(car_arm_bool, car_run_bool);

        TimeUpdate = Time.now();
    }
}