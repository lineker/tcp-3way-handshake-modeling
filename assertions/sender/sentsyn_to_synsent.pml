#include "../../tcp.pml"

/* receiverchan?[SYN] -> X senderState == SYN_SENT */

never  {    /* ![](p->X b) */
T0_init:
	if
	:: (SENDER_SENT_SYN) -> goto accept_S0
	:: (1) -> goto T0_init
	fi;
accept_S0:
	if
	:: (! SENDER_AT_SYNSENT) -> goto accept_all
	fi;
accept_all:
	skip
}
