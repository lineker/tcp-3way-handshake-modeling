/* wrong_synack_senderuid.pml - Set returning senderuid incorrectly */

#define MUTANT_SENDER_WRONT_SENDERUID {printf("[S] [Mutant] Setting wrong senderuid .\n"); temp = 0;}

#include "../../tcp.pml"