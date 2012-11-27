// TCP 3-way handshake modeling
// Lineker Tomazeli (insert McGill ID here) and Etienne Perot (260377858)

#define chansize 5    // Channel size
#define connections 2 // Number of times to allow the sender to reconnect. Used to limit the search space when model checking.
#define maxmessages 5 // Maximum number of messages to send per connection. Used to limit the search space when model checking.
#define timeout true  // Allow timeout (true) or not (false)

mtype = {SYN, SYN_ACK, ACK, FIN_ACK, MSG_ACK};

chan senderchan = [chansize] of {mtype, int, int};   // Sender uses this channel to receive messages
chan receiverchan = [chansize] of {mtype, int, int}; // Receiver uses this channel to receive messages
chan messagechan = [chansize] of {int, int};         // {recipient, message}, channel used to transmit messages. recipient designates which proctype the message is meant to receive the message.

byte ready = 1;
byte ready2 = 1;

active proctype Sender()
{
	int senderuid = 0, receiveruid, message = 1, temp, totalconnections = 0, nummessages;

	// TCP three way handshake starts here

	CLOSED:
	L:
		(ready == 1); // Wait for receiver channel to be ready
		ready = 0;
		nummessages = 0; // We have sent 0 messages so far
		do // Flush sender channel
		:: senderchan ? _, _, _;
		:: empty(senderchan) -> break;
		od;
		printf("[S] --- Sender flushed ---\n");
		senderuid = senderuid + 1;
		receiverchan ! SYN, senderuid, 0; // Send SYN

	SYN_SENT:
		printf("[S] Sent SYN\n");
		senderchan ? SYN_ACK, receiveruid, temp;
		printf("[S] Received SYN+ACK\n");

	SYN_RCVD: // State once we've received a SYN+ACK message
		if // Check if the sequence number matches
		:: temp != senderuid + 1 ->
			printf("[S] senderuid sent by receiver doesn't match the expected value! Resetting state.\n");
			goto CLOSE;
		:: else -> skip;
		fi;
		senderuid = temp;
		receiveruid = receiveruid + 1;
		printf("[S] Sending ACK\n");
		receiverchan ! ACK, senderuid, receiveruid;

	ESTABLISHED:
		// Start sending messages
		nummessages = nummessages + 1;
		messagechan ! receiveruid, message;
		printf("[S] Message %d sent (%d sent so far)\n", message, nummessages);
		if
		:: senderchan ? MSG_ACK, temp ->
			printf("[S] Received MSG_ACK\n");
			if
			:: nummessages < maxmessages -> // Maybe we want to send another message...
				message = message + 1;
				printf("[S] Decided to send another message %d\n", message);
				goto ESTABLISHED;
			:: true -> // ... or maybe we don't
				printf("[S] Decided not to send another message, closing connection.\n");
				goto CLOSE;
			fi;
		:: timeout -> // We didn't get response, so timeout
			if
			:: true -> // Try to resend the message
				printf("[S] Timeout: trying to resend message %d\n", message);
				goto ESTABLISHED;
			:: true -> // if we never get MSG_ACK we can decide to close the connection
				printf("[S] Timeout: Giving up, closing connection\n");
				goto CLOSE;
			fi;
		fi;

	CLOSE:
		receiverchan ! FIN_ACK, senderuid, receiveruid;
		printf("[S] Sent FIN_ACK to receiver\n");

	FIN_WAIT_1:
		if
		:: senderchan ? FIN_ACK, receiveruid, senderuid->
			printf("[S] Received FIN_ACK from receiver\n");
		:: timeout ->
			printf("[S] Timeout: Did NOT receive FIN_ACK from receiver!\n");
		fi;

	FIN_WAIT:
		receiverchan ! ACK, senderuid, receiveruid;
		printf("[S] --- Sender closed ---\n");
		ready2 = 1; // Set ready so receiver can clean up
		if
		:: totalconnections < connections ->
			totalconnections = totalconnections + 1;
			goto CLOSED;
		:: else ->
			printf("[S] Sender reached max connections; process terminating.\n");
		fi;
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
	int receiveruid = 0, senderuid, message, temp, last_received = 0, totalconnections = 0;

	CLOSED:
		ready2 = 0;

	LISTEN:
		receiverchan ? SYN, senderuid, temp; // Wait for SYN
		printf("[R] Received SYN\n");
		receiveruid = receiveruid + 1; // increment sequence number
		senderchan ! SYN_ACK, receiveruid, senderuid + 1; // Send back SYN+ACK
		printf("[R] Sent SYN+ACK\n");

	SYN_RCVD:
		receiverchan ? ACK, senderuid, temp;
		printf("[R] Received ACK\n");
		if
		:: temp != receiveruid + 1 ->
			printf("[R] Sequence number (receiveruid) send by sender doesn't match the expected value! Closing.\n");
			goto CLOSE_WAIT;
		:: else -> skip;
		fi;
		receiveruid = temp;

	ESTABLISHED:
		do 
		:: messagechan ? receiveruid, message -> // Receive a message
			printf("[R] Message received %d\n", message);
			if
			:: true ->
				if
				:: message <= last_received ->
					printf("[R] Message %d already received, so ignore. It was probably a retransmission.\n", message);
				:: else -> // Send ack that message was received
					last_received = message;
					senderchan ! MSG_ACK, message;
					printf("[R] Sent MSG_ACK for message %d\n", message);
				fi;
			:: timeout -> // possible timeout
				printf("[R] Receiver timeout, waiting for another message.\n");
				goto ESTABLISHED;
			fi;
		:: receiverchan ? FIN_ACK, senderuid, receiveruid ->
			printf("[R] Received FIN_ACK from sender\n");
			goto CLOSE_WAIT;
		/*if we don't receive any other msg*/
		/*:: timeout->
			printf("server sent CLOSE \n");
			goto CLOSE;*/
		od;

	CLOSE_WAIT:
		senderchan ! FIN_ACK, receiveruid, senderuid;
		printf("[R] Sent FIN_ACK to sender\n");
		if
		:: receiverchan ? ACK, senderuid, receiveruid ->
			printf("[R] Received the last ACK\n");
		:: timeout->
			printf("[R] Receiver timeout: did NOT receive LAST_ACK\n");
		fi;

	LAST_ACK:
		printf("[R] --- Receiver closed ---\n");
		ready2 == 1; // Wait for sender to be finalized
		do // Flush message channel
		:: messagechan ? _, _;
		:: empty(messagechan) -> break;
		od;
		do // flush receiver channel
		:: receiverchan ? _, _, _;
		:: empty(receiverchan) -> break;
		od;
		printf("[R] --- Receiver flushed ---\n");
		ready = 1; // set ready so that the sender can clean up
		if
		:: totalconnections < connections ->
			totalconnections = totalconnections + 1;
			goto CLOSED;
		:: else ->
			printf("[R] Receiver reached max connections; process terminating.\n");
		fi;
}
