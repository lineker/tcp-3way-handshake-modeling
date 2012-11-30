/* closewait_lastack.pml - Check if the receiver moves from state CLOSE_WAIT to LAST_ACK */

#include "../../tcp.pml"

never  {    /* ![](receiver_CLOSE_WAIT -> (receiver_CLOSE_WAIT U receiver_LAST_ACK)) */
T0_init:
        if
        :: (! ((receiver_LAST_ACK)) && (receiver_CLOSE_WAIT)) -> goto accept_S4
        :: (1) -> goto T0_init
        fi;
accept_S4:
        if
        :: (! ((receiver_LAST_ACK))) -> goto accept_S4
        :: (! ((receiver_CLOSE_WAIT)) && ! ((receiver_LAST_ACK))) -> goto accept_all
        fi;
accept_all:
        skip
}