/* output_finack.pml - The receiver may only send FIN_ACK messages in the CLOSE_WAIT state. */

#include "../../tcp.pml"

never  {    /* ![](senderchan_FIN_ACK -> receiver_CLOSE_WAIT) */
T0_init:
        if
        :: (! ((receiver_CLOSE_WAIT)) && (senderchan_FIN_ACK)) -> goto accept_all
        :: (1) -> goto T0_init
        fi;
accept_all:
        skip
}