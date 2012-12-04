/* receiver.pml - Receiver process */

/* Receiver states */
#define receiver_CLOSED      receiverState == CLOSED
#define receiver_LISTEN      receiverState == LISTEN
#define receiver_SYN_RCVD    receiverState == SYN_RCVD
#define receiver_ESTABLISHED receiverState == ESTABLISHED
#define receiver_CLOSE_WAIT  receiverState == CLOSE_WAIT
#define receiver_LAST_ACK    receiverState == LAST_ACK
#define receiver_TERMINATED  receiverState == TERMINATED

/* Receiver input events */
#define receiverchan_SYN     receiverchan?[SYN]
#define receiverchan_ACK     receiverchan?[ACK]
#define receiverchan_SYN_ACK receiverchan?[SYN_ACK]
#define receiverchan_FIN_ACK receiverchan?[FIN_ACK]

/* Receiver output events */
#define senderchan_SYN_ACK   senderchan?[SYN_ACK]
#define senderchan_MSG_ACK   senderchan?[MSG_ACK]
#define senderchan_FIN_ACK   senderchan?[FIN_ACK]

int receiver_totalconnections = 0;

active proctype Receiver()
{
	int receiveruid = 0, senderuid, message, temp, last_received;

	l_CLOSED: {
		receiverState = CLOSED;
		last_received = 0;
	}

	l_LISTEN: {
		receiverState = LISTEN;
		atomic {
			receiverchan ? SYN, senderuid, temp; /* Wait for SYN */
			printf("[R] Received SYN\n");
#ifdef MUTANT_RECEIVER_SEND_INVALID_MSG_ACK
			MUTANT_RECEIVER_SEND_INVALID_MSG_ACK
#endif
			receiveruid = receiveruid + 1; /* increment sequence number */
			senderchan ! SYN_ACK, receiveruid, senderuid + 1; /* Send back SYN+ACK */
			printf("[R] Sent SYN+ACK\n");
		}
	}

	l_SYN_RCVD: {
		atomic {
			receiverState = SYN_RCVD;
			receiverchan ? SYN_ACK, senderuid, temp;
		}
		printf("[R] Received SYN+ACK\n");
		if
		:: temp != receiveruid + 1 ->
			printf("[R] Sequence number (receiveruid) send by sender doesn't match the expected value! Closing.\n");
			goto l_CLOSE_WAIT;
		:: else -> skip;
		fi;
		receiveruid = temp;
	}

	l_ESTABLISHED: {
		receiverState = ESTABLISHED;
		do
		:: messagechan ? temp, message -> /* Receive a message */
#ifdef MUTANT_RECEIVER_CORRUPT_PAYLOAD
			MUTANT_RECEIVER_CORRUPT_PAYLOAD
#endif
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
					printf("[R] [Payload] Receiver commits to payload \"%d\". Payload hash: %d -> %d\n", message, payloadHashReceived, payloadHashReceived * hashmod + message % hashmod);
					payloadHashReceived = payloadHashReceived * hashmod + message % hashmod;
					last_received = temp;
				fi;
				senderchan ! MSG_ACK, last_received, 0;
				printf("[R] Sent MSG_ACK for message #%d\n", last_received);
			:: true -> /* Possible timeout */
				printf("[R] Receiver pretending we didn't see the message, waiting for retransmission.\n");
			fi;
			goto l_ESTABLISHED;
#ifdef MUTANT_RECEIVER_FIN_ACK_WRONG_GUARD
		:: true ->
			MUTANT_RECEIVER_FIN_ACK_WRONG_GUARD
#else
		:: receiverchan ? FIN_ACK, senderuid, receiveruid ->
#endif
			printf("[R] Received FIN_ACK from sender\n");
#ifdef MUTANT_RECEIVER_DONT_CLOSE
			MUTANT_RECEIVER_DONT_CLOSE
#endif
			goto l_CLOSE_WAIT;  /* change state because we received a FIN */
		od;
	}

	l_CLOSE_WAIT: {
		receiverState = CLOSE_WAIT;
		printf("[R] Clearing out leftover messages in message channel (if any)...\n");
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
	}

	l_LAST_ACK: {
#ifdef MUTANT_RECEIVER_SET_WRONG_STATE
		MUTANT_RECEIVER_SET_WRONG_STATE
#else
		receiverState = LAST_ACK;
#endif
		printf("[R] --- Receiver closed ---\n");
		if
		:: receiver_totalconnections < connections ->
			receiver_totalconnections = receiver_totalconnections + 1;
			goto l_CLOSED;
		:: else ->
			printf("[R] Receiver reached max connections; process terminating.\n");
		fi;
	}
	receiverState = TERMINATED;
}
