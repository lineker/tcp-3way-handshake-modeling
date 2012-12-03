/* sent_ack_established.pml - Check if the sender 
 moves to state ESTABLISHED to after sending ACK */

#include "../../tcp.pml"

never  {    /* ![](receiverchan_ACK->X sender_ESTABLISHED) */
T0_init:
	if
	:: (receiverchan_ACK) -> goto accept_S0
	:: (1) -> goto T0_init
	fi;
accept_S0:
	if
	:: (! sender_ESTABLISHED) -> goto accept_all
	fi;
accept_all:
	skip
}
