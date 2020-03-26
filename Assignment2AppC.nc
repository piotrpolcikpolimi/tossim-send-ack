#include "Assignment2.h"

configuration Assignment2AppC {}

implementation {


/****** COMPONENTS *****/
    components MainC, ActiveMessageC;

    components new AMSenderC(AM_ID) as Sender;
    components new AMReceiverC(AM_ID) as Receiver;
    components new TimerMilliC() as Timer;
    components Assignment2C as App;

    //add the other components here
    components new FakeSensorC();

/****** INTERFACES *****/
    //Boot interface
    App.Boot -> MainC.Boot;

    /****** Wire the other interfaces down here *****/
    App.AMSend -> Sender;
    App.Packet -> Sender;
    App.Receive -> Receiver;
    App.AMControl -> ActiveMessageC;
    App.MTimer -> Timer;

    App.Read -> FakeSensorC;
}

