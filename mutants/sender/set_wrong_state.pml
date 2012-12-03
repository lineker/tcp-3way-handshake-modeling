/* set_wrong_state.pml - Set state to CLOSED in the ESTABLISHED block */

#define MUTANT_SENDER_SET_WRONG_STATE {printf("[S] [Mutant] Setting state to CLOSED.\n"); senderState = CLOSED;}

#include "../../tcp.pml"