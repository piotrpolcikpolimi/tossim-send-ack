#include "Assignment2.h"
#include "Timer.h"

module Assignment2C {

    uses {
        /****** INTERFACES *****/
        interface Boot; 

        interface Timer<TMilli> as MilliTimer;
        interface SplitControl as AMControl;
        interface AMSend;
        interface Receive;
        interface Packet;

        //interface used to perform sensor reading (to get the value from a sensor)
        interface Read<uint16_t>;
    }

} implementation {

    uint8_t counter = 0;
    uint8_t rec_id;
    message_t packet;
    uint8_t retryCounter = 0;

    void sendReq();
    void sendResp();
    void retryOrTimeout();


    //***************** Send request function ********************//
    void sendReq() {
        /* This function is called when we want to send a request
         *
         * STEPS:
         * 1. Prepare the msg
         * 2. Set the ACK flag for the message using the PacketAcknowledgements interface
         *     (read the docs)
         * 3. Send an UNICAST message to the correct node
         * X. Use debug statements showing what's happening (i.e. message fields)
         */
    }

  //****************** Task send response *****************//
    void sendResp() {
        /* This function is called when we receive the REQ message.
         * Nothing to do here. 
         * `call Read.read()` reads from the fake sensor.
         * When the reading is done it raise the event read one.
         */
        call Read.read();
    }

    void retryOrTimeout() {
        retryCounter++;
        if (retryCounter < RADIO_START_TIMEOUT_LIMIT) {
            call AMControl.start();
        } else {
            call AMControl.stop();
        }
    }

  //***************** Boot interface ********************//
    event void Boot.booted() {
        dbg("boot","Device %u booted.\n", TOS_NODE_ID);
        call AMControl.start();
        /* Fill it ... */
    }

  //***************** SplitControl interface ********************//
    event void SplitControl.startDone(error_t err){
        if (err == SUCCESS) {
            call MilliTimer.startPeriodic(MOTE_FREQ)
        } else {
            retryOrTimeout();
        }
    }

    event void SplitControl.stopDone(error_t err){
        /* Fill it ... */
    }

    //***************** MilliTimer interface ********************//
    event void MilliTimer.fired() {
        dbg("timer_event", "Mote %u\n", TOS_NODE_ID);
    }


    //********************* AMSend interface ****************//
    event void AMSend.sendDone(message_t* buf,error_t err) {
        /* This event is triggered when a message is sent 
         *
         * STEPS:
         * 1. Check if the packet is sent
         * 2. Check if the ACK is received (read the docs)
         * 2a. If yes, stop the timer. The program is done
         * 2b. Otherwise, send again the request
         * X. Use debug statements showing what's happening (i.e. message fields)
         */
    }

    //***************************** Receive interface *****************//
    event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
        /* This event is triggered when a message is received 
         *
         * STEPS:
         * 1. Read the content of the message
         * 2. Check if the type is request (REQ)
         * 3. If a request is received, send the response
         * X. Use debug statements showing what's happening (i.e. message fields)
         */
    }

  //************************* Read interface **********************//
    event void Read.readDone(error_t result, uint16_t data) {
        double value = ((double)data/65535)*100;
        dbg("boot","temp read done %f\n",value);
        /* This event is triggered when the fake sensor finish to read (after a Read.read()) 
         *
         * STEPS:
         * 1. Prepare the response (RESP)
         * 2. Send back (with a unicast message) the response
         * X. Use debug statement showing what's happening (i.e. message fields)
         */
    }
}

