/* listen_synrcvd_or_closewait.pml - Check if the receiver moves from state SYN_RCVD to either ESTABLISHED or CLOSE_WAIT */

#include "../../tcp.pml"

never  {    /* ![](receiverchan_ACK -> ((receiverchan_ACK || receiver_SYN_RCVD) U (receiver_ESTABLISHED || receiver_CLOSE_WAIT))) */
T0_init:
        if
        :: (! ((receiver_ESTABLISHED || receiver_CLOSE_WAIT)) && (receiverchan_ACK)) -> goto accept_S4
        :: (! ((receiver_ESTABLISHED || receiver_CLOSE_WAIT)) && ! ((receiverchan_ACK || receiver_SYN_RCVD)) && (receiverchan_ACK)) -> goto accept_all
        :: (1) -> goto T0_init
        fi;
accept_S4:
        if
        :: (! ((receiver_ESTABLISHED || receiver_CLOSE_WAIT))) -> goto accept_S4
        :: (! ((receiver_ESTABLISHED || receiver_CLOSE_WAIT)) && ! ((receiverchan_ACK || receiver_SYN_RCVD))) -> goto accept_all
        fi;
accept_all:
        skip
}