/* sent_finack_to_finwait.pml - Check if the sender 
 moves to state FIN_WAIT_1 to after sending FIN_ACK */

#include "../../tcp.pml"

never  {    /* ![](receiverchan_FIN_ACK->X sender_FIN_WAIT_1) */
T0_init:
	if
	:: (receiverchan_FIN_ACK) -> goto accept_S0
	:: (1) -> goto T0_init
	fi;
accept_S0:
	if
	:: (! (senderState == FIN_WAIT_1)) -> goto accept_all
	fi;
accept_all:
	skip
}
