/* fin_ack_wrong_guard.pml - Pretend we received a FIN_ACK message even if we didn't */

#define MUTANT_RECEIVER_FIN_ACK_WRONG_GUARD {printf("[R] [Mutant] Pretending we received a FIN_ACK.\n");}

#include "../../tcp.pml"