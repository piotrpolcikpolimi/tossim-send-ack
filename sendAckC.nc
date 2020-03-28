#include "sendAck.h"
#include "Timer.h"

module sendAckC {

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
    }

    //****************** Task send response *****************//
    void sendResp() {
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
            dbg("radio_send","Request sent, counter value %u\n", counter-1);
            if (wasAcked) {
                dbg("radio_ack" , "Request was acked. Stoping the timer.\n");
                call MilliTimer.stop();
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

            if (msg_rec->type == 1) {
                dbg("radio_rec", "Request received. Counter value: %u\n", msg_rec->counter);
                sendResp();
            }

            if (msg_rec->type == 2) {
                dbg("radio_rec", "Response received. Value is %f, counter is: %u\n", ((double)msg_rec->value/65535)*100, msg_rec->counter);
            }
        }
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

        dbg("role", "Preparing response for mote %u. Type: %u, counter: %u, value: %f\n", TOS_NODE_ID, RESP, msg->counter, ((double)msg->value/65535)*100);

        call Ack.requestAck(&packet);
        if (call AMSend.send(1, &packet, sizeof(my_msg_t)) == SUCCESS) {
        }
    }
}

