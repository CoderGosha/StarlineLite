using Toybox.Time.Gregorian;
using Toybox.Position;
using Toybox.Lang;

public enum LockStatus{
    Undefined = 1,
    Lock = 2,
    Unlock = 3,
    RunAndUnlock = 4,
    RunAndLock = 5,
    RemoteRun = 6
}

public class CarState
{
    public var LockStatus as LockStatus;
    public var CarName as Lang.String or Null;
    public var StatusCode as Lang.Number; 
    public var DeviceId as Lang.String or Null;
    public var TempEngine as Lang.String or Null;
    public var TempInside as Lang.String or Null;
    public var TimeUpdate as Lang.Number or Toybox.Time.Moment; 
    public var ErrorMessage as Lang.String; 
    public var position_longitude = 0 as Lang.Float;
    public var position_latitude = 0 as Lang.Float;
    public var position_car;

    function initialize() {
        LockStatus = Undefined;        
        CarName = CacheModule.GetCacheProperty("starline_car_name");
        StatusCode = 0;
        TimeUpdate = 0;
        DeviceId = CacheModule.GetCacheProperty("starline_car_device_id");
        ErrorMessage = "";
    }

    function GetUpdateTime() as Lang.String {
        if (TimeUpdate == 0)
        {
            return "-";
        }
        var today = Gregorian.info(TimeUpdate, Time.FORMAT_LONG);
        var dateString = today.hour;
        if (today.min < 10)
        {
            dateString += ":0" + today.min;
        }
        else
        {
            dateString += ":" + today.min;
        }

        return dateString;
    }

    function SetProperty(property as Lang.Dictionary) {
            StatusCode = 200;
            TimeUpdate = Time.now();

            CarName = property.get("alias");
            TempInside = property.get("ctemp");
            TempEngine = property.get("etemp");
            DeviceId = property.get("device_id");

            var car_state = property.get("car_state") as Lang.Dictionary;
            if (car_state != null){
                var car_arm = car_state.get("arm") as Lang.Boolean;
                var car_run = car_state.get("run") as Lang.Boolean;
                var car_r_start = car_state.get("r_start") as Lang.Boolean;
                SetLockState(car_arm, car_run, car_r_start);
            }

           // var position = property.get("position");
            // if (position != null){
            //     position_longitude = position.get("x") as Lang.Float;
            //     position_latitude = position.get("y") as Lang.Float;
            //     position_car = new Position.Location(
            //         {
            //             :latitude => position_latitude,
            //             :longitude => position_longitude,
            //             :format => :degrees
            //         }
            //      );
            //  }
            
            CacheModule.SetCacheProperty("starline_car_name", CarName);
            CacheModule.SetCacheProperty("starline_car_device_id", DeviceId);
    }

    function SetLockState(car_arm as Lang.Boolean, car_run as Lang.Boolean, car_r_start as Lang.Boolean) {
        if (car_r_start){
            LockStatus = RemoteRun;
        }
        else if (car_arm && car_run)
        {
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

    function SetResultCommand(property as Lang.Dictionary) {
        var car_arm = property.get("arm") as Lang.String;
        var car_run = property.get("run") as Lang.String;
        var car_arm_bool = false;
        var car_run_bool = false;

        if (car_arm.toNumber() == 1){
            car_arm_bool = true;
        }

        if (car_run.toNumber() == 1){
            car_run_bool = true;
        }

        SetLockState(car_arm_bool, car_run_bool, false);

        TimeUpdate = Time.now();
    }
}