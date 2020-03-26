#ifndef SENDACK_H
#define SENDACK_H

#define REQ 1
#define RESP 2 

//payload of the msg
typedef nx_struct my_msg {
    nx_uint8_t msg_type;
    nx_uint16_t msg_counter;
    nx_uint16_t value;
} my_msg_t;



enum {
    AM_MY_MSG = 6,
    MOTE_FREQ = 1000,
    RADIO_START_TIMEOUT_LIMIT = 100
};

#endif
