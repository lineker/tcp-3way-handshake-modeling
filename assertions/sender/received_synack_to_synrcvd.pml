#include "../../tcp.pml"

/* receiverchan?[SYN] -> senderState == SYN_SENT */

never  {    /* ![](p->X b) */
T0_init:
	if
	:: (SENDER_RECEIVED_SYNACK) -> goto accept_S0
	:: (1) -> goto T0_init
	fi;
accept_S0:
	if
	:: (! SENDER_AT_SYNRCVD) -> goto accept_all
	fi;
accept_all:
	skip
}