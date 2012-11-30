/* established_closewait.pml - Check if the receiver moves from state ESTABLISHED to CLOSE_WAIT */

#include "../../tcp.pml"

never  {    /* ![](receiverchan_FIN_ACK -> ((receiverchan_FIN_ACK || receiver_ESTABLISHED) U receiver_CLOSE_WAIT)) */
T0_init:
        if
        :: (! ((receiver_CLOSE_WAIT)) && (receiverchan_FIN_ACK)) -> goto accept_S4
        :: (! ((receiver_CLOSE_WAIT)) && ! ((receiverchan_FIN_ACK || receiver_ESTABLISHED)) && (receiverchan_FIN_ACK)) -> goto accept_all
        :: (1) -> goto T0_init
        fi;
accept_S4:
        if
        :: (! ((receiver_CLOSE_WAIT))) -> goto accept_S4
        :: (! ((receiver_CLOSE_WAIT)) && ! ((receiverchan_FIN_ACK || receiver_ESTABLISHED))) -> goto accept_all
        fi;
accept_all:
        skip
}