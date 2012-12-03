/* corrupt_payload.pml - Corrupt received payload */

#define MUTANT_RECEIVER_CORRUPT_PAYLOAD {printf("[R] [Mutant] Corrupting payload \"%d\" to \"%d\".\n", message, (message * 157) % 23); message = (message * 157) % 23;}

#include "../../tcp.pml"