/* imm_fin_ack_channel_empty.pml - Check if receiverchan is empty once we receive a FIN_ACK */

#define IMM_RECEIVER_FIN_ACK_CHANNEL_EMPTY assert empty(receiverchan);

#include "../../tcp.pml"