/* closewait_sender_ended.pml - The receiver can only be in state CLOSE_WAIT if the sender is in FIN_WAIT_1 or later */

#include "../../tcp.pml"

never  {    /* ![](receiver_CLOSE_WAIT -> (sender_FIN_WAIT_1 || sender_CLOSED || sender_TERMINATED)) */
T0_init:
        if
        :: (! ((sender_FIN_WAIT_1 || sender_CLOSED || sender_TERMINATED)) && (receiver_CLOSE_WAIT)) -> goto accept_all
        :: (1) -> goto T0_init
        fi;
accept_all:
        skip
}