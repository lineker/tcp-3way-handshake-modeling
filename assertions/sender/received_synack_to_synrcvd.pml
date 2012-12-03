* received_synack_to_synrcvd.pml - Check if the sender moves to state SYN_RCVD when received SYN_ACK  */

#include "../../tcp.pml"

never  {    /* ![](senderchan_SYN_ACK -> sender_SYN_RCVD) */
T0_init:
	if
	:: (senderchan_SYN_ACK) -> goto accept_S0
	:: (1) -> goto T0_init
	fi;
accept_S0:
	if
	:: (! sender_SYN_RCVD) -> goto accept_all
	fi;
accept_all:
	skip
}