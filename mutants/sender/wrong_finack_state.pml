/* wrong_finack_state.pml - Set wrong state after sending fin_ack to receiver */

#define MUTANT_SENDER_FINACK_WRONG_STATE {printf("[S] [Mutant] Setting wrong state after FIN_ACK .\n"); senderState = CLOSED;}

#include "../../tcp.pml"