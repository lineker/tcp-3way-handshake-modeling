/* 
TCP 3-way handshake modeling
Lineker Tomazeli (insert McGill ID here) and Etienne Perot (260377858)
*/

#define chansize 5    /* Channel size */
#define connections 4 /* Number of times to allow the sender to reconnect. Used to limit the search space when model checking.*/
#define maxmessages 5 /* Maximum number of messages to send per connection. Used to limit the search space when model checking. */
#define timeout true  /* Allow timeout (true) or not (false) */

/* TCP flags */
mtype = {SYN, SYN_ACK, ACK, FIN_ACK, MSG_ACK};

/* States */
mtype = {CLOSED, SYN_SENT, SYN_RCVD, ESTABLISHED, FIN_WAIT_1, FIN_WAIT, LISTEN, CLOSE_WAIT, LAST_ACK};

chan senderchan = [chansize] of {mtype, int, int};   /* Sender uses this channel to receive messages */
chan receiverchan = [chansize] of {mtype, int, int}; /* Receiver uses this channel to receive messages */
chan messagechan = [chansize] of {int, int};         /* {message number, message content}, channel used to transmit messages. */

byte senderState;
byte receiverState;

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

active proctype Receiver()
{
	int receiveruid = 0, senderuid, message, temp, last_received, totalconnections = 0;

	l_CLOSED:
		receiverState = CLOSED;
		last_received = 0;

	l_LISTEN:
		receiverState = LISTEN;
		receiverchan ? SYN, senderuid, temp; /* Wait for SYN */
		printf("[R] Received SYN\n");
		receiveruid = receiveruid + 1; /* increment sequence number */
		atomic {
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
