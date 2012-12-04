/* lastack_end.pml - Check if the receiver LAST_ACK to CLOSED or exits */

#include "../../tcp.pml"

never  {    /* ![](receiver_LAST_ACK -> (receiver_LAST_ACK U (receiver_CLOSED || (receiver_totalconnections >= connections && receiver_TERMINATED)))) */
T0_init:
        if
        :: (! ((receiver_CLOSED || (receiver_totalconnections >= connections && receiver_TERMINATED))) && (receiver_LAST_ACK)) -> goto accept_S4
        :: (1) -> goto T0_init
        fi;
accept_S4:
        if
        :: (! ((receiver_CLOSED || (receiver_totalconnections >= connections && receiver_TERMINATED)))) -> goto accept_S4
        :: (! ((receiver_CLOSED || (receiver_totalconnections >= connections && receiver_TERMINATED))) && ! ((receiver_LAST_ACK))) -> goto accept_all
        fi;
accept_all:
        skip
}