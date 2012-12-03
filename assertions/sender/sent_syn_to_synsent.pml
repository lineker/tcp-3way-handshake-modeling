/* sent_syn_to_synsent.pml - Check if the sender moves 
to state SYN_SENT after sending SYN */

#include "../../tcp.pml"

never  {    /* ![](receiverchan_SYN->X sender_SYN_SENT) */
T0_init:
	if
	:: (receiverchan_SYN) -> goto accept_S0
	:: (1) -> goto T0_init
	fi;
accept_S0:
	if
	:: (! sender_SYN_SENT) -> goto accept_all
	fi;
accept_all:
	skip
}
