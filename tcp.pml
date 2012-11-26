#define chansize 5 /*channel size*/
#define timeout 1 /* possible timeout*/

mtype = {SYN, SYN_ACK, ACK, FIN_ACK, MSG_ACK};

chan senderchan = [chansize] of {mtype,byte,byte}; /*sender uses this channel to receive message*/
chan receiverchan = [chansize] of {mtype,byte,byte}; /*receiver uses this channel to receive message*/
chan messagechan = [chansize] of {byte,byte}; /*{receiveruid, message}, channel used to transmit messages */

active proctype Sender()
{
	printf("sender \n");
	byte	senderuid = 0,
			receiveruid,
			message = 1,
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
		if /*do we have to check for this?! */
		:: (temp != senderuid+1)->
			printf("senderuid send by receiver dont match \n");
			/*goto close connection*/
			goto CLOSE;
		::else->skip;
		fi;
		senderuid = temp;
		receiveruid = receiveruid+1;
		printf("send ACK \n");
		receiverchan!ACK,senderuid,receiveruid; /* send ACK */

	ESTABLISHED:
		/* start sending messages*/
		messagechan!receiveruid,message;
		printf("message %d sent \n",message);

		if
		:: senderchan?MSG_ACK,temp->
			printf("received MSG_ACK\n");
			if 
			::(true)-> /*want to send next message*/
				printf("send next message \n");
				message = message+1;
				goto ESTABLISHED;
			::(true)-> /*dont want to send messages anymore, start close*/
				printf("dont want to send next msg, start close \n");
				goto CLOSE;
			fi;
		:: timeout -> /*didn't get response, so timeout*/
			if
			:: (true)-> /*timeout but try to resend*/
				printf("sender timeout: resend message %d \n",message);
				goto ESTABLISHED;
			:: (true)-> /*if we never get MSG_ACK we can close*/
				printf("sender timeout: start close \n");
				goto CLOSE;
			fi;
		fi;

	CLOSE:
		receiverchan!FIN_ACK,senderuid,receiveruid;
		printf("sent FIN_ACK to receiver \n");
	FIN_WAIT_1:
		if 
		:: senderchan?FIN_ACK,receiveruid,senderuid->
			printf("received FIN_ACK from receiver \n");
		:: timeout-> 
			printf("sender timeout: did NOT receive FIN_ACK from receiver \n");
		fi;
	FIN_WAIT:
		receiverchan!ACK,senderuid,receiveruid;
		/*goto CLOSED;*/
}

active proctype Receiver()
{
	byte	receiveruid = 0,
			senderuid,
			message,
			temp,
			last_received = 0;

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
			goto CLOSE_WAIT;
		::else->skip;
		fi;
		receiveruid = temp;

	ESTABLISHED:
		do 
		:: messagechan?receiveruid,message-> /*receive message*/
			printf("message received %d\n",message);
			if
			:: (true) ->
				if
				:: (message <= last_received)->
					printf("msg %d already received, so ignore \n",message);
				:: else-> /*send ack that message was received*/
					last_received = message;
					senderchan!MSG_ACK,message;
					printf("sent MSG_ACK \n");
				fi;
			:: timeout -> /*possible timeout*/
				printf("receiver timeout\n");
				goto ESTABLISHED;
			fi;
		:: receiverchan?FIN_ACK,senderuid,receiveruid->
			printf("received FIN_ACK from sender \n");
			goto CLOSE_WAIT;
		/*if we don't receive any other msg*/
		/*:: timeout->
			printf("server sent CLOSE \n");
			goto CLOSE;*/
		od;

	CLOSE_WAIT:
		senderchan!FIN_ACK,receiveruid,senderuid;
		printf("sent FIN_ACK to sender \n");
		if 
		:: receiverchan?ACK,senderuid,receiveruid-> 
			printf("received the last ACK\n");
		:: timeout-> 
			printf("receiver timeout: did NOT receive LAST_ACK \n");
		fi;
	LAST_ACK:
		/*goto LISTEN:*/

		



}