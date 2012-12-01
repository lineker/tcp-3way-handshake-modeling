/* transmission_integrity.pml - Check if the data received by the receiver matches what the sender sent */

#include "../tcp.pml"

active proctype integrityCheck() {
	(senderState == TERMINATED && receiverState == TERMINATED); /* Wait for both processes to terminate */
	assert payloadHashSent != 0 && payloadHashSent == payloadHashReceived; /* Now check that the hashes are equal */
}
