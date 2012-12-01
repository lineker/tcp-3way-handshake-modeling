/* output_msgack.pml - The receiver may only send MSG_ACK messages in the ESTABLISHED state,
 * though the sender may not have received them by the time the receiver switches to the CLOSE_WAIT state. */

#include "../../tcp.pml"

never  {    /* ![](senderchan_MSG_ACK -> (receiver_ESTABLISHED || receiver_CLOSE_WAIT)) */
T0_init:
        if
        :: (! ((receiver_ESTABLISHED || receiver_CLOSE_WAIT)) && (senderchan_MSG_ACK)) -> goto accept_all
        :: (1) -> goto T0_init
        fi;
accept_all:
        skip
}