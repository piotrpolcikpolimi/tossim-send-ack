/**
 *  Configuration file for wiring of Assignment2C module to other common 
 *  components needed for proper functioning
 *
 *  @author Luca Pietro Borsani
 */

#include "Assignment2.h"

configuration Assignment2AppC {}

implementation {


/****** COMPONENTS *****/
  components MainC, Assignment2C as App;
  //add the other components here
  components new FakeSensorC();
 
/****** INTERFACES *****/
  //Boot interface
  App.Boot -> MainC.Boot;

  /****** Wire the other interfaces down here *****/
  //Send and Receive interfaces
  //Radio Control
  //Interfaces to access package fields
  //Timer interface
  //Fake Sensor read
  App.Read -> FakeSensorC;

}

