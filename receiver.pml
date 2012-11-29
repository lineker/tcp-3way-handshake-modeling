/* receiver.pml - Receiver process */

// Receiver states
#define receiver_CLOSED   receiverState == CLOSED
#define receiver_LISTEN   receiverState == LISTEN
#define receiver_SYN_RCVD receiverState == SYN_RCVD

// Receiver input events
#define receiverchan_SYN receiverchan?[SYN]

active proctype Receiver()
{
	int receiveruid = 0, senderuid, message, temp, last_received, totalconnections = 0;

	l_CLOSED:
		receiverState = CLOSED;
		last_received = 0;

	l_LISTEN:
		receiverState = LISTEN;
		atomic {
			receiverchan ? SYN, senderuid, temp; /* Wait for SYN */
			printf("[R] Received SYN\n");
			receiveruid = receiveruid + 1; /* increment sequence number */
			senderchan ! SYN_ACK, receiveruid, senderuid + 1; /* Send back SYN+ACK */
			printf("[R] Sent SYN+ACK\n");
			receiverState = SYN_RCVD; /* Set state */
		}

	l_SYN_RCVD:
		receiverchan ? ACK, senderuid, temp;
		printf("[R] Received ACK\n");
		if
		:: temp != receiveruid + 1 ->
			printf("[R] Sequence number (receiveruid) send by sender doesn't match the expected value! Closing.\n");
			goto l_CLOSE_WAIT;
		:: else -> skip;
		fi;
		atomic {
			receiveruid = temp;
			receiverState = ESTABLISHED;
		}

	l_ESTABLISHED:
		do
		:: messagechan ? temp, message -> /* Receive a message */
			printf("[R] Message #%d received with payload \"%d\"\n", temp, message);
			if
			:: temp < last_received ->
				printf("[R] Message #%d was already received (last = %d), so ignore. It was probably a retransmission.\n", message, last_received);
			:: temp >= last_received -> /* Send ACK that message was received */
				if
				:: temp == last_received ->
					printf("[R] Message #%d is the same as the one last received. Our acknowledgement probably got ignored. Acknowledging again.\n", temp);
				:: temp > last_received ->
					printf("[R] Message #%d is a new message. Acknowledging.\n", temp);
					last_received = temp;
				fi;
				senderchan ! MSG_ACK, last_received, 0;
				printf("[R] Sent MSG_ACK for message #%d\n", last_received);
			:: true -> /* Possible timeout */
				printf("[R] Receiver pretending we didn't see the message, waiting for retransmission.\n");
			fi;
			goto l_ESTABLISHED;
		:: receiverchan ? FIN_ACK, senderuid, receiveruid ->
			printf("[R] Received FIN_ACK from sender\n");
			receiverState = CLOSE_WAIT; /* change state bc we received a FIN */
			goto l_CLOSE_WAIT;
		/*if we don't receive any other msg*/
		/*:: timeout->
			printf("server sent CLOSE \n");
			goto CLOSE;*/
		od;

	l_CLOSE_WAIT:
		printf("clearing out leftover messages in message channel (if any)...\n");
		do
		:: messagechan ? temp, message ->
			printf("[R] Received leftover message #%d from sender, with payload \"%d\"\n", temp, message);
		:: empty(messagechan) ->
			break;
		od;
		senderchan ! FIN_ACK, receiveruid, senderuid;
		printf("[R] Sent FIN_ACK to sender\n");
		receiverchan ? ACK, senderuid, receiveruid;
		printf("[R] Received the last ACK\n");
		receiverState = LAST_ACK;

	l_LAST_ACK:
		printf("[R] --- Receiver closed ---\n");
		(senderState == CLOSED); /* Wait for sender to be finalized */

		do /* Flush receiver channel */
		:: receiverchan ? _, _, _;
		:: empty(receiverchan) -> break;
		od;
		printf("[R] --- Receiver flushed ---\n");
		if
		:: totalconnections < connections ->
			totalconnections = totalconnections + 1;
			goto l_CLOSED;
		:: else ->
			printf("[R] Receiver reached max connections; process terminating.\n");
		fi;
}
