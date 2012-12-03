/* established_eventually_finwait.pml - Check if the sender eventually moves from state ESTABLISHED to state FIN_WAIT_1 properly */

#include "../../tcp.pml"

never  {    /* ![](sender_ESTABLISHED -> <> sender_FIN_WAIT_1) */
T0_init:
	if
	:: (! ((sender_FIN_WAIT_1)) && (sender_ESTABLISHED)) -> goto accept_S4
	:: (1) -> goto T0_init
	fi;
accept_S4:
	if
	:: (! ((sender_FIN_WAIT_1))) -> goto accept_S4
	fi;
}