/* synsent_until_synack.pml - Check if the receiver stay on  state SYN_SENT until receives an SYN_ACK */

#include "../../tcp.pml"

never  {    /* ![](sender_SYN_SENT -> (sender_SYN_SENT U senderchan_SYN_ACK)) */
T0_init:
        if
        :: (! ((senderchan_SYN_ACK)) && (sender_SYN_SENT)) -> goto accept_S4
        :: (1) -> goto T0_init
        fi;
accept_S4:
        if
        :: (! ((senderchan_SYN_ACK))) -> goto accept_S4
        :: (! ((sender_SYN_SENT)) && ! ((senderchan_SYN_ACK))) -> goto accept_all
        fi;
accept_all:
        skip
}