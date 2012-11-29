/* listen_synrcvd.pml - Check if the receiver moves from state LISTEN to state SYN_RCVD properly */

#include "../../tcp.pml"

never  {    /* ![](receiverchan_SYN -> (receiver_LISTEN U receiver_SYN_RCVD)) */
T0_init:
        if
        :: (! ((receiver_SYN_RCVD)) && (receiverchan_SYN)) -> goto accept_S4
        :: (! ((receiver_LISTEN)) && ! ((receiver_SYN_RCVD)) && (receiverchan_SYN)) -> goto accept_all
        :: (1) -> goto T0_init
        fi;
accept_S4:
        if
        :: (! ((receiver_SYN_RCVD))) -> goto accept_S4
        :: (! ((receiver_LISTEN)) && ! ((receiver_SYN_RCVD))) -> goto accept_all
        fi;
accept_all:
        skip
}