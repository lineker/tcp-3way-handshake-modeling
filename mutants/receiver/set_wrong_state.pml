/* set_wrong_state.pml - Set state to CLOSED in the LAST_ACK block */

#define MUTANT_RECEIVER_SET_WRONG_STATE {printf("[R] [Mutant] Setting state to CLOSED.\n"); receiverState = CLOSED;}

#include "../../tcp.pml"