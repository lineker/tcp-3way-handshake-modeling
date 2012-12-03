/* accept_all_messages.pml - Consider every message as valid, even retransmissions. */

#define MUTANT_RECEIVER_ACCEPT_ALL_MESSAGES {printf("[R] [Mutant] Accepting message.\n");}

#include "../../tcp.pml"