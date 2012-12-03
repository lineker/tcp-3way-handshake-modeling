/* dont_close.pml - Don't go into the CLOSE_WAIT state when we get a FIN_ACK message; instead go into SYN_RCVD */

#define MUTANT_RECEIVER_DONT_CLOSE {printf("[R] [Mutant] Jumping to SYN_RCVD"); goto l_SYN_RCVD;}

#include "../../tcp.pml"