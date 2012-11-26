#define chansize 5 /*channel size*/

mtype = {SYN, SYN_ACK, ACK, FIN_ACK, MSG_ACK};

chan senderchan = [chansize] of {mtype,byte,byte}; /*sender uses this channel to receive message*/
chan receiverchan = [chansize] of {mtype,byte,byte}; /*receiver uses this channel to receive message*/
chan messagechan = [chansize] of {byte,byte}; /*{receiveruid, message}, channel used to transmit messages */

active proctype Sender()
{
	printf("sender \n");
	byte	senderuid = 0,
			receiveruid,
			message = 0,
			temp;

	/* TCP three way handshake start here*/
	CLOSED: /* state */
		senderuid = senderuid + 1; /*increment senderuid*/
		printf("send SYN \n");
		receiverchan!SYN,senderuid;/* send SYN */
	SYN_SENT: /* state */
		senderchan?SYN_ACK,receiveruid,temp;
		printf("received SYN+ACK \n");
	SYN_RCVD: /* state , received SYN+ACK */
		printf("here\n");
		if /*do we have to check for this?! */
		:: (temp != senderuid+1)->
			printf("senderuid send by receiver dont match \n");
			/*goto close connection*/
			goto CLOSE;
		::else->skip;
		fi;
		printf("here2\n");
		senderuid = temp;
		receiveruid = receiveruid+1;
		printf("send ACK \n");
		receiverchan!ACK,senderuid,receiveruid;

	ESTABLISHED:
			/* start sending messages*/
			messagechan!receiveruid,message;
			printf("message sent \n");
			senderchan?MSG_ACK,temp;
	/* send SYN+ACK */

	/*data transfer*/
	CLOSE:
}

active proctype Receiver()
{
	byte	receiveruid = 0,
			senderuid,
			message,
			temp;

	printf("receiver \n");
	LISTEN:
		receiverchan?SYN,senderuid; /*receives SYN*/
		printf("received SYN \n");
		receiveruid = receiveruid + 1; /*increment uid*/
		printf("send SYN+ACK \n");
		senderchan!SYN_ACK,receiveruid,senderuid+1; /*send back SYN+ACK*/
		
	SYN_RCVD:
		receiverchan?ACK,senderuid,temp;
		printf("received ACK \n");
		/*do we have to check if uid return from sender matchs receiveruid?*/
		if 
		:: (temp != receiveruid+1)->
			printf("receiveruid send by sender dont match \n");
			/*goto close connection*/
			goto CLOSE;
		::else->skip;
		fi;
		receiveruid = temp;

	ESTABLISHED:
		messagechan?receiveruid,message;
		printf("message received \n");
		senderchan!MSG_ACK,message;

	CLOSE:

}