// sender.pml - Sender process

active proctype Sender()
{
	int senderuid = 0, receiveruid, message = 1, temp, totalconnections = 0, nummessages;

	/* TCP three way handshake starts here */
	senderState = CLOSED; /*initial state*/
	l_CLOSED:
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

	l_SYN_SENT:
		printf("[S] Sent SYN\n");
		atomic {
			senderchan ? SYN_ACK, receiveruid, temp;
			senderState = SYN_RCVD; /* State once we've received a SYN+ACK message */
		}
		printf("[S] Received SYN+ACK\n");

	l_SYN_RCVD: /* State once we've received a SYN+ACK message */
		if /* Check if the sequence number matches */
		:: temp != senderuid + 1 ->
			printf("[S] senderuid sent by receiver doesn't match the expected value! Resetting state.\n");
			goto l_CLOSE;
		:: else -> skip;
		fi;
		senderuid = temp;
		receiveruid = receiveruid + 1;
		printf("[S] Sending ACK\n");
		atomic {
			receiverchan ! ACK, senderuid, receiveruid;
			senderState = ESTABLISHED;
		}

	l_ESTABLISHED:
		/* Start sending messages */
		messagechan ! senderuid, message;
		printf("[S] Sent message #%d with payload \"%d\" (%d messages sent so far)\n", senderuid, message, nummessages);
		if
		:: senderchan ? MSG_ACK, temp, 0 ->
			if
			:: temp == senderuid ->
				printf("[S] Received MSG_ACK about message #%d, which is the latest message we've sent, so it was successfully received.\n", temp);
				senderuid = senderuid + 1;
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
			if
			:: true -> /* Try to resend the message */
				printf("[S] Timeout: trying to resend message #%d\n", senderuid);
			:: true -> /* If we never get MSG_ACK we can decide to close the connection */
				printf("[S] Timeout: Giving up, closing connection\n");
				goto l_CLOSE;
			fi;
		fi;
		goto l_ESTABLISHED;

	l_CLOSE:
		atomic {
			receiverchan ! FIN_ACK, senderuid, receiveruid;
			senderState = FIN_WAIT_1;
		}
		printf("[S] Sent FIN_ACK to receiver\n");

	l_FIN_WAIT_1:
		do
		:: senderchan ? MSG_ACK, _, _ ->
			printf("[S] Received a retransmitted MSG_ACK. Ignoring, because we are trying to close the connection here.\n");
		:: senderchan ? FIN_ACK, receiveruid, senderuid ->
			printf("[S] Received FIN_ACK from receiver\n");
			goto l_FIN_WAIT;
		od;

	l_FIN_WAIT:
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
/*never {	 process main cannot remain at L forever 
accept:	do
	:: main@L
	od
}*/

/*never  {     ![](p->X b) this LTL is not working yet :)
T0_init:
	if
	:: ((receiverchan?[SYN])) -> goto accept_S0
	:: (1) -> goto T0_init
	fi;
accept_S0:
	if
	:: !(Sender@SYN_SENT) -> goto accept_all
	fi;
accept_all:
	skip
} */