/* receiver_states.pml - Check if the receiver moves from state to state properly */

#include "../tcp.pml"

#define receiver_CLOSED receiverState == CLOSED
#define receiver_LISTEN receiverState == LISTEN

never  {    /* !(receiver_CLOSED -> (receiver_CLOSED U receiver_LISTEN)) */
accept_init:
T0_init:
        if
        :: (! ((receiver_LISTEN)) && (receiver_CLOSED)) -> goto accept_S3
        fi;
accept_S3:
T0_S3:
        if
        :: (! ((receiver_LISTEN))) -> goto accept_S3
        :: (! ((receiver_CLOSED)) && ! ((receiver_LISTEN))) -> goto accept_all
        fi;
accept_all:
        skip
}