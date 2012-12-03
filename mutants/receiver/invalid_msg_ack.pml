/* invalid_msg_ack.pml - Send a MSG_ACK in a state where we shouldn't */

#define MUTANT_RECEIVER_SEND_INVALID_MSG_ACK {printf("[R] [Mutant] Sending invalid MSG_ACK\n"); senderchan ! MSG_ACK, 0, 0;}

#include "../../tcp.pml"