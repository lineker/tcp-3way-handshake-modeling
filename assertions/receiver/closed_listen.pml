/* closed_listen.pml - Check if the receiver moves from state CLOSED to state LISTEN properly */

#include "../../tcp.pml"

never  {    /* ![](receiver_CLOSED -> (receiver_CLOSED U receiver_LISTEN)) */
T0_init:
        if
        :: (! ((receiver_LISTEN)) && (receiver_CLOSED)) -> goto accept_S4
        :: (1) -> goto T0_init
        fi;
accept_S4:
        if
        :: (! ((receiver_LISTEN))) -> goto accept_S4
        :: (! ((receiver_CLOSED)) && ! ((receiver_LISTEN))) -> goto accept_all
        fi;
accept_all:
        skip
}