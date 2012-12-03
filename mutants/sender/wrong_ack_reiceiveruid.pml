/* wrong_ack_reiceiveruid.pml - Set returning reiceiveruid incorrectly */

#define MUTANT_SENDER_WRONG_RECEIVERUID {printf("[S] [Mutant] Setting wrong reiceiveruid .\n"); receiveruid = 0;}

#include "../../tcp.pml"