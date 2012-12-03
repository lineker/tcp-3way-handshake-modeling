/* sender.pml - Sender process */

/* Sender states */
#define sender_zero        senderState == 0
#define sender_CLOSED      senderState == CLOSED
#define sender_SYN_SENT    senderState == SYN_SENT
#define sender_SYN_RCVD    senderState == SYN_RCVD
#define sender_ESTABLISHED senderState == ESTABLISHED
#define sender_FIN_WAIT_1  senderState == FIN_WAIT_1
#define sender_TERMINATED  senderState == TERMINATED

active proctype Sender()
{
	int senderuid = 0, receiveruid, message = 1, temp, totalconnections = 0, nummessages;

	/* TCP three way handshake starts here */
	senderState = CLOSED; /*initial state*/
	l_CLOSED: {
		(receiverState == LISTEN);/* wait for recevier channel to be ready */
		nummessages = 0; /* We have sent 0 messages so far */
		do /* Flush sender channel */
		:: senderchan ? _, _, _;
		:: empty(senderchan) -> break;
		od;
		printf("[S] --- Sender flushed ---\n");
		senderuid = senderuid + 1;
		atomic {
			receiverchan ! SYN, senderuid, 0; /* Send SYN */
			senderState = SYN_SENT;
		}
	}
#ifdef MUTANT_SENDER_ESTABLISHED_BEFORE_SYN_ACK
		MUTANT_SENDER_ESTABLISHED_BEFORE_SYN_ACK
#endif
	l_SYN_SENT: {
		printf("[S] Sent SYN\n");
		atomic {
			senderchan ? SYN_ACK, receiveruid, temp;
			senderState = SYN_RCVD; /* State once we've received a SYN+ACK message */
		}
		printf("[S] Received SYN+ACK\n");
	}

	l_SYN_RCVD: { /* State once we've received a SYN+ACK message */
#ifdef MUTANT_SENDER_WRONG_SENDERUID
		MUTANT_SENDER_WRONG_SENDERUID
#endif
		if 
		:: temp != senderuid + 1 ->
			printf("[S] senderuid sent by receiver doesn't match the expected value! Resetting state.\n");
			goto l_CLOSE;
		:: else -> skip;
		fi;
		senderuid = temp;
		receiveruid = receiveruid + 1;
#ifdef MUTANT_SENDER_WRONG_RECEIVERUID
		MUTANT_SENDER_WRONG_RECEIVERUID
#endif
		printf("[S] Sending SYN+ACK\n");
		atomic {
			receiverchan ! SYN_ACK, senderuid, receiveruid;
			senderState = ESTABLISHED;
		}
	}

	l_ESTABLISHED: {
#ifdef MUTANT_SENDER_SET_WRONG_STATE
		MUTANT_SENDER_SET_WRONG_STATE
#endif
		/* Start sending messages */
		messagechan ! senderuid, message;
		printf("[S] Sent message #%d with payload \"%d\" (%d messages sent so far)\n", senderuid, message, nummessages);
		if
		:: senderchan ? MSG_ACK, temp, 0 ->
			if
			:: temp == senderuid ->
				printf("[S] Received MSG_ACK about message #%d, which is the latest message we've sent, so it was successfully received.\n", temp);
				senderuid = senderuid + 1;
				printf("[S] [Payload] Sender commits to payload \"%d\". Payload hash: %d -> %d\n", message, payloadHashSent, payloadHashSent * hashmod + message % hashmod);
				payloadHashSent = payloadHashSent * hashmod + message % hashmod;
				nummessages = nummessages + 1;
				if
				:: nummessages < maxmessages -> /* Maybe we want to send another message... */
					message = message + 1;
					printf("[S] Decided to send another message.\n", message);
				:: true -> /* ... or maybe we don't */
					printf("[S] Decided not to send another message, closing connection.\n");
					goto l_CLOSE;
				fi;
			:: temp < senderuid ->
				printf("[S] Received MSG_ACK about message #%d, which is an old message. Retransmitting message.\n", temp);
			:: true ->
				printf("[S] Received MSG_ACK about message #%d, but pretending it got dropped by the network. Ignoring.\n", temp);
			fi;
		:: empty(senderchan) -> /* We didn't get response, so timeout */
			/* Try to resend the message */
			printf("[S] Timeout: trying to resend message #%d\n", senderuid);
		fi;
		goto l_ESTABLISHED;
	}

	l_CLOSE: {

		atomic {
			receiverchan ! FIN_ACK, senderuid, receiveruid;
#ifdef MUTANT_SENDER_FINACK_WRONG_STATE
			MUTANT_SENDER_FINACK_WRONG_STATE
#else
			senderState = FIN_WAIT_1;
#endif
		}
		printf("[S] Sent FIN_ACK to receiver\n");
	}

	l_FIN_WAIT_1: {
		do
		:: senderchan ? MSG_ACK, _, _ ->
			printf("[S] Received a retransmitted MSG_ACK. Ignoring, because we are trying to close the connection here.\n");
		:: senderchan ? FIN_ACK, receiveruid, senderuid ->
			printf("[S] Received FIN_ACK from receiver\n");
			goto l_FIN_WAIT;
		od;
	}

	l_FIN_WAIT: {
		atomic {
			receiverchan ! ACK, senderuid, receiveruid;
			senderState = CLOSED;
			printf("[S] --- Sender closed ---\n");
			if
			:: totalconnections < connections ->
				totalconnections = totalconnections + 1;
				goto l_CLOSED;
			:: else ->
				printf("[S] Sender reached max connections; process terminating.\n");
			fi;
		}
	}
	senderState = TERMINATED;
}
