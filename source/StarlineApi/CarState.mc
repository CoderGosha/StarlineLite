enum LockStatus{
    Undefined = "Undefined",
    Lock = "Lock",
    Unlock = "Unlock"
}

class CarState
{
    public var LockStatus as LockStatus;
    function initialize() {
        LockStatus = Undefined;
    }
}