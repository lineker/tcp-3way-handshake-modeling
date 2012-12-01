/* output_synack.pml - The receiver may only send SYN_ACK messages in the LISTEN state,
 * though the sender may not have received them by the time the receiver switches to the SYN_RCVD state. */

#include "../../tcp.pml"

never  {    /* ![](senderchan_SYN_ACK -> (receiver_LISTEN || receiver_SYN_RCVD)) */
T0_init:
        if
        :: (! ((receiver_LISTEN || receiver_SYN_RCVD)) && (senderchan_SYN_ACK)) -> goto accept_all
        :: (1) -> goto T0_init
        fi;
accept_all:
        skip
}