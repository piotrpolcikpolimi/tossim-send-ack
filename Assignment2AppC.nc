#include "Assignment2.h"

configuration AssignmentAppC {}

implementation {

/****** COMPONENTS *****/
    components MainC;


    components sendAckC as App;
    //add the other components here

/****** INTERFACES *****/
    App.Boot -> MainC.Boot;

    /****** Wire the other interfaces down here *****/
    //Send and Receive interfaces
    //Radio Control
    //Interfaces to access package fields
    //Timer interface
    //Fake Sensor read
    App.Read -> FakeSensorC;

}

