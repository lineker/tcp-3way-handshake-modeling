/* established_until_finack.pml - Check if the sender 
moves from state ESTABLISHED to state receiverchan_FIN_ACK 
properly */

#include "../../tcp.pml"

never  {    /* ![](sender_ESTABLISHED -> (sender_ESTABLISHED U receiverchan_FIN_ACK)) */
T0_init:
        if
        :: (! ((receiverchan_FIN_ACK)) && (sender_ESTABLISHED)) -> goto accept_S4
        :: (1) -> goto T0_init
        fi;
accept_S4:
        if
        :: (! ((receiverchan_FIN_ACK))) -> goto accept_S4
        :: (! ((sender_ESTABLISHED)) && ! ((receiverchan_FIN_ACK))) -> goto accept_all
        fi;
accept_all:
        skip
}