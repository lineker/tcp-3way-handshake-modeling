/* connection_start.pml - The receiver can only be CLOSED if the sender is CLOSED as well or has sent a SYN (SYN_SENT) */

#include "../../tcp.pml"

never  {    /* ![](receiver_CLOSED -> (sender_CLOSED || sender_SYN_SENT || sender_zero)) */
T0_init:
        if
        :: (! ((sender_CLOSED || sender_SYN_SENT || sender_zero)) && (receiver_CLOSED)) -> goto accept_all
        :: (1) -> goto T0_init
        fi;
accept_all:
        skip
}