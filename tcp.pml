#define chansize 5 /*channel size*/
#define timeout 1 /* possible timeout*/

mtype = {SYN, SYN_ACK, ACK, FIN_ACK, MSG_ACK};
mtype = {CLOSED,SYN_SENT,SYN_RCVD,ESTABLISHED,FIN_WAIT_1,FIN_WAIT,LISTEN,CLOSE_WAIT,LAST_ACK}

chan senderchan = [chansize] of {mtype,int,int}; /*sender uses this channel to receive message*/
chan receiverchan = [chansize] of {mtype,int,int}; /*receiver uses this channel to receive message*/
chan messagechan = [chansize] of {int,int}; /*{receiveruid, message}, channel used to transmit messages */

byte senderState;
byte receiverState;

active proctype Sender ()
{
	printf("sender \n");
	int	senderuid = 0,
			receiveruid,
			message = 1,
			temp;

	/* TCP three way handshake start here*/
	l_CLOSED: /* state */
		senderState = CLOSED;
		(receiverState == LISTEN);/* wait for recevier channel to be ready */
		do/*flush sender chan*/
		:: senderchan?_,_,_;
		:: empty(senderchan) -> break;
		od;
		printf("--- sender flushed ---\n");
 	
		senderuid = senderuid + 1; /*increment senderuid*/
		
		receiverchan!SYN,senderuid,0;/* send SYN */
	l_SYN_SENT: /* state */
		senderState = SYN_SENT;
		printf("sent SYN \n");
		senderchan?SYN_ACK,receiveruid,temp;
		printf("received SYN+ACK \n");
	l_SYN_RCVD: /* state , received SYN+ACK */
		senderState = SYN_RCVD;
		if /*do we have to check for this?! */
		:: (temp != senderuid+1)->
			printf("senderuid send by receiver dont match \n");
			/*goto close connection*/
			goto l_CLOSE;
		::else->skip;
		fi;
		senderuid = temp;
		receiveruid = receiveruid+1;
		printf("send ACK \n");
		receiverchan!ACK,senderuid,receiveruid; /* send ACK */

	l_ESTABLISHED:
		senderState = ESTABLISHED;
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
				goto l_ESTABLISHED;
			::(true)-> /*dont want to send messages anymore, start close*/
				printf("dont want to send next msg, start close \n");
				goto l_CLOSE;
			fi;
		:: timeout -> /*didn't get response, so timeout*/
			if
			:: (true)-> /*timeout but try to resend*/
				printf("sender timeout: resend message %d \n",message);
				goto l_ESTABLISHED;
			:: (true)-> /*if we never get MSG_ACK we can close*/
				printf("sender timeout: start close \n");
				goto l_CLOSE;
			fi;
		fi;

	l_CLOSE:
		receiverchan!FIN_ACK,senderuid,receiveruid;
		printf("sent FIN_ACK to receiver \n");
	l_FIN_WAIT_1:
		senderState = FIN_WAIT_1;
		if 
		:: senderchan?FIN_ACK,receiveruid,senderuid->
			printf("received FIN_ACK from receiver \n");
		:: timeout-> 
			printf("sender timeout: did NOT receive FIN_ACK from receiver \n");
		fi;
	l_FIN_WAIT:
		senderState = FIN_WAIT;
		receiverchan!ACK,senderuid,receiveruid;
		printf("--- sender closed ---\n");
		
		goto l_CLOSED;
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
	:: !(senderState == SYN_SENT) -> goto accept_all
	fi;
accept_all:
	skip
}*/


active proctype Receiver()
{
	int	receiveruid = 0,
			senderuid,
			message,
			temp,
			last_received = 0;

	printf("receiver \n");

	l_CLOSED:
		receiverState = CLOSED;
	l_LISTEN:
		receiverState = LISTEN;
		receiverchan?SYN,senderuid,temp; /*receives SYN*/
		printf("received SYN \n");
		receiveruid = receiveruid + 1; /*increment uid*/
		senderchan!SYN_ACK,receiveruid,senderuid+1; /*send back SYN+ACK*/
		printf("sent SYN+ACK \n");
	l_SYN_RCVD:
		receiverState = SYN_RCVD;
		receiverchan?ACK,senderuid,temp;
		printf("received ACK \n");
		/*do we have to check if uid return from sender matchs receiveruid?*/
		if 
		:: (temp != receiveruid+1)->
			printf("receiveruid send by sender dont match \n");
			/*goto close connection*/
			goto l_CLOSE_WAIT;
		::else->skip;
		fi;
		receiveruid = temp;

	l_ESTABLISHED:
		receiverState = ESTABLISHED;
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
				goto l_ESTABLISHED;
			fi;
		:: receiverchan?FIN_ACK,senderuid,receiveruid->
			receiverState = CLOSE_WAIT;
			printf("received FIN_ACK from sender \n");
			goto l_CLOSE_WAIT;
		/*if we don't receive any other msg*/
		/*:: timeout->
			printf("server sent CLOSE \n");
			goto CLOSE;*/
		od;

	l_CLOSE_WAIT:
		senderchan!FIN_ACK,receiveruid,senderuid;
		printf("sent FIN_ACK to sender \n");
		if 
		:: receiverchan?ACK,senderuid,receiveruid-> 
			printf("received the last ACK\n");
		:: timeout-> 
			printf("receiver timeout: did NOT receive LAST_ACK \n");
		fi;
	l_LAST_ACK:
		receiverState = LAST_ACK;
		printf("--- receiver closed ---\n");
		(senderState == CLOSED); /*wait for sender to finalized*/

		do /* flush message chan*/
		:: messagechan?_,_;
		:: empty(messagechan) -> break;
		od;
		do /* flush receiver chan*/
		:: receiverchan?_,_,_;
		:: empty(receiverchan) -> break;
		od;
		printf("--- receiver flushed ---\n");

		goto l_CLOSED;

}

/*never  {     !<>p U b 
T0_init:
	if
	:: ((b)) -> goto accept_all
	:: (! ((p))) -> goto T0_S2
	fi;
accept_S7:
	if
	:: (! ((p))) -> goto accept_S7
	fi;
T0_S2:
	if
	:: (! ((p))) -> goto T0_S2
	:: (! ((p)) && (b)) -> goto accept_S7
	fi;
accept_all:
	skip
}*/

