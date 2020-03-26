#ifndef SENDACK_H
#define SENDACK_H

//payload of the msg
typedef nx_struct my_msg {
    //field 1
    //field 2
    //field 3
} my_msg_t;

#define REQ 1
#define RESP 2 

enum {
    AM_MY_MSG = 6,
    MOTE_FREQ = 1000,
    RADIO_START_TIMEOUT_LIMIT = 100
};

#endif
