/* established_before_synack.pml - Set state to ESTABLISHED before receiving SYN_ACK */

#define MUTANT_SENDER_ESTABLISHED_BEFORE_SYN_ACK {printf("[S] [Mutant] Setting state to ESTABLISHED.\n"); senderState = ESTABLISHED; goto l_ESTABLISHED;}

#include "../../tcp.pml"