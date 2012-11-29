/* 
TCP 3-way handshake modeling
Lineker Tomazeli (insert McGill ID here) and Etienne Perot (260377858)
*/

#define chansize 5    /* Channel size */
#define connections 4 /* Number of times to allow the sender to reconnect. Used to limit the search space when model checking.*/
#define maxmessages 5 /* Maximum number of messages to send per connection. Used to limit the search space when model checking. */
#define timeout true  /* Allow timeout (true) or not (false) */

/* TCP flags */
mtype = {SYN, SYN_ACK, ACK, FIN_ACK, MSG_ACK};

/* States */
mtype = {CLOSED, SYN_SENT, SYN_RCVD, ESTABLISHED, FIN_WAIT_1, FIN_WAIT, LISTEN, CLOSE_WAIT, LAST_ACK};

chan senderchan = [chansize] of {mtype, int, int};   /* Sender uses this channel to receive messages */
chan receiverchan = [chansize] of {mtype, int, int}; /* Receiver uses this channel to receive messages */
chan messagechan = [chansize] of {int, int};         /* {message number, message content}, channel used to transmit messages. */

byte senderState;
byte receiverState;

#include "sender.pml"
#include "receiver.pml"
