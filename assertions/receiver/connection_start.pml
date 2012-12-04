/* connection_start.pml - The receiver can only be CLOSED if the sender is not actively maintaining a connection */

#include "../../tcp.pml"

never  {    /* ![](receiver_CLOSED -> !(sender_ESTABLISHED || sender_SYN_RCVD)) */
T0_init:
        if
        :: ((receiver_CLOSED) && (sender_ESTABLISHED || sender_SYN_RCVD)) -> goto accept_all
        :: (1) -> goto T0_init
        fi;
accept_all:
        skip
}