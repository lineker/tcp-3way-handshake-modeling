/* wrong_synack_senderuid.pml - Set returning senderuid incorrectly */

#define MUTANT_WRONT_SENDERUID {printf("[S] [Mutant] Setting wrong senderuid .\n"); temp = 999;}

#include "../../tcp.pml"