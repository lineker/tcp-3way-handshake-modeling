/* sent_finalack_to_closed.pml - Check if the sender moves 
from state FIN_ACK to state CLOSED properly */

#include "../../tcp.pml"

never  {    /* ![](receiverchan_ACK->X sender_CLOSED) */
T0_init:
	if
	:: (receiverchan_ACK) -> goto accept_S0
	:: (1) -> goto T0_init
	fi;
accept_S0:
	if
	:: (! sender_CLOSED) -> goto accept_all
	fi;
accept_all:
	skip
}
