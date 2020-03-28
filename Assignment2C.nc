#include "Assignment2.h"
#include "Timer.h"

module Assignment2C {

    uses {
        /****** INTERFACES *****/
        interface Boot; 

        interface Timer<TMilli> as MilliTimer;
        interface SplitControl as AMControl;
        interface PacketAcknowledgements as Ack;
        interface AMSend;
        interface Receive;
        interface Packet;
        

        //interface used to perform sensor reading (to get the value from a sensor)
        interface Read<uint16_t>;
    }

} implementation {

    uint8_t counter = 0;
    uint8_t rec_id;
    bool locked = FALSE;
    message_t packet;
    uint8_t retryCounter = 0;
    my_msg_t* msg_rec;

    void sendReq();
    void sendResp();
    void retryOrTimeout();


    //***************** Send request function ********************//
    void sendReq() {
        if (locked) {
            return;
        } else {
            my_msg_t* msg = (my_msg_t*)call Packet.getPayload(&packet, sizeof(my_msg_t));
            if (msg == NULL) {
                return;
            }

            msg->type = REQ;
            msg->counter = counter;
            dbg("role", "Preparing request for mote %u. Type: %u, counter: %u\n", TOS_NODE_ID, REQ, counter);

            call Ack.requestAck(&packet);
            if (call AMSend.send(2, &packet, sizeof(my_msg_t)) == SUCCESS) {
                counter++;
                locked = TRUE;
            }
        }
        
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
            dbgerror("radio", "Radio for device %u failed. Retrying.\n", TOS_NODE_ID);
            call AMControl.start();
        } else {
            dbgerror("radio", "Radio for device %u failed. Terminating.\n", TOS_NODE_ID);
            call AMControl.stop();
        }
    }


  //***************** Boot interface ********************//
    event void Boot.booted() {
        dbg("boot","Device %u booted.\n", TOS_NODE_ID);
        call AMControl.start();
    }

  //***************** AMControl interface ********************//
    event void AMControl.startDone(error_t err){
        if (err == SUCCESS) {
            dbg("radio", "Radio for device %u started.\n", TOS_NODE_ID);
            if (TOS_NODE_ID == 1) {
                call MilliTimer.startPeriodic(MOTE_FREQ);
            }
        } else {
            retryOrTimeout();
        }
    }

    event void AMControl.stopDone(error_t err){}

    //***************** MilliTimer interface ********************//
    event void MilliTimer.fired() {
        sendReq();
    }


    //********************* AMSend interface ****************//
    event void AMSend.sendDone(message_t* buf, error_t err) {
        my_msg_t* msg = (my_msg_t*)call Packet.getPayload(&packet, sizeof(my_msg_t));
        bool wasAcked = call Ack.wasAcked(buf);

        if (&packet == buf && err == SUCCESS) {
            locked = FALSE;
        }

        if (msg->type == REQ) {
            dbg("radio_send","Request sent, counter value %u\n", counter);
            if (wasAcked) {
                dbg("radio_ack" , "Request was acked. Stoping the timer.\n");
            } else {
                dbg("radio_ack", "Request was not acked. Retrying.\n");
            }
        } else {
            dbg("radio_ack", "Response was sent.\n");
            if (wasAcked) {
                dbg("radio_ack", "Response was acked. Terminating\n");
            } else {
                dbg("radio_ack", "Response FAILED to be acked. Terminating\n");
            }

        }
    }

    //***************************** Receive interface *****************//
    event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
        if (len != sizeof(my_msg_t)) {
            return buf;
        } else {
            msg_rec = (my_msg_t*)payload;
            dbg("boot", "counter value %u\n", msg_rec->counter);
            if (msg_rec->type == 1) {
                dbg("radio_rec", "Request received. Counter value: %u\n", msg_rec->counter);
                sendResp();
            }
            if (msg_rec->type == 2) {
                dbg("radio_rec", "Response received. Value is %f, counter is: %u\n", ((double)msg_rec->value/65535)*100, msg_rec->counter);
            }
        }
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
        my_msg_t* msg = (my_msg_t*)call Packet.getPayload(&packet, sizeof(my_msg_t));
        if (msg == NULL) {
            return;
        }
        msg->type = RESP;
        msg->counter = msg_rec->counter;
        msg->value = data;
        dbg("role", "Preparing response for mote %u. Type: %u, counter: %u, value: %f\n.", TOS_NODE_ID, RESP, msg->counter, ((double)msg->value/65535)*100)
        call Ack.requestAck(&packet);
        if (call AMSend.send(1, &packet, sizeof(my_msg_t)) == SUCCESS) {
        }
        /* This event is triggered when the fake sensor finish to read (after a Read.read()) 
         *
         * STEPS:
         * 1. Prepare the response (RESP)
         * 2. Send back (with a unicast message) the response
         * X. Use debug statement showing what's happening (i.e. message fields)
         */
    }
}

