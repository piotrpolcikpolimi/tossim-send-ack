#include "Assignment2.h"

configuration Assignment2AppC {}

implementation {


/****** COMPONENTS *****/
    components MainC, ActiveMessageC;

    components new AMSenderC(AM_MY_MSG) as Sender;
    components new AMReceiverC(AM_MY_MSG) as Receiver;
    components new TimerMilliC() as Timer;
    components new FakeSensorC();

    components Assignment2C as App;

/****** INTERFACES *****/
    //Boot interface
    App.Boot -> MainC.Boot;

    /****** Wire the other interfaces down here *****/
    App.AMSend -> Sender;
    App.Packet -> Sender;
    App.Receive -> Receiver;
    App.AMControl -> ActiveMessageC;
    App.MilliTimer -> Timer;

    App.Read -> FakeSensorC;
}

