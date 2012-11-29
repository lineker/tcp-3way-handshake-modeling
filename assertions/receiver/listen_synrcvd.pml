/* listen_synrcvd.pml - Check if the receiver moves from state LISTEN to state SYN_RCVD properly */

#include "../../tcp.pml"

never  {    /* ![](receiverchan_SYN -> X receiver_SYN_RCVD) */
T0_init:
        if
        :: ((receiverchan_SYN)) -> goto accept_S0
        :: (1) -> goto T0_init
        fi;
accept_S0:
        if
        :: (! ((receiver_SYN_RCVD))) -> goto accept_all
        fi;
accept_all:
        skip
}