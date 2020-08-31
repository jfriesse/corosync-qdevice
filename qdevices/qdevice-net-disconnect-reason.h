/*
 * Copyright (c) 2015-2020 Red Hat, Inc.
 *
 * All rights reserved.
 *
 * Author: Jan Friesse (jfriesse@redhat.com)
 *
 * This software licensed under BSD license, the text of which follows:
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 * - Neither the name of the Red Hat, Inc. nor the names of its
 *   contributors may be used to endorse or promote products derived from this
 *   software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef _QDEVICE_NET_DISCONNECT_REASON_H_
#define _QDEVICE_NET_DISCONNECT_REASON_H_


#ifdef __cplusplus
extern "C" {
#endif

enum qdevice_net_disconnect_reason {
	/* Undefined reason. If this error appears, it's error in source code */
	QDEVICE_NET_DISCONNECT_REASON_UNDEFINED,

	/* Received known message, but it was not expected */
	QDEVICE_NET_DISCONNECT_REASON_UNEXPECTED_MSG,
	/* Received unknown message */
	QDEVICE_NET_DISCONNECT_REASON_UNSUPPORTED_MSG,
	/* TLS setting of server and client are incompatible */
	QDEVICE_NET_DISCONNECT_REASON_INCOMPATIBLE_TLS,
	/* MSG setting of server and client are incompatible */
	QDEVICE_NET_DISCONNECT_REASON_INCOMPATIBLE_MSG_SIZE,
	/* Message doesn't contain required option */
	QDEVICE_NET_DISCONNECT_REASON_REQUIRED_OPTION_MISSING,

	/* Can't allocate send list item or message is too long to fit into send buffer */
	QDEVICE_NET_DISCONNECT_REASON_CANT_ALLOCATE_MSG_BUFFER,
	/* Impossible to create or update heartbeat sending timer */
	QDEVICE_NET_DISCONNECT_REASON_CANT_SCHEDULE_HB_TIMER,
	/* Impossible to create or update votequorum poll timer */
	QDEVICE_NET_DISCONNECT_REASON_CANT_SCHEDULE_VOTING_TIMER,
	/* Impossible to create or update regular heuristics timer */
	QDEVICE_NET_DISCONNECT_REASON_CANT_SCHEDULE_HEURISTICS_TIMER,
	/* Impossible to exec heuristics */
	QDEVICE_NET_DISCONNECT_REASON_CANT_START_HEURISTICS,
	/* Impossible to activate/deactive heuristics result notifier */
	QDEVICE_NET_DISCONNECT_REASON_CANT_ACTIVATE_HEURISTICS_RESULT_NOTIFIER,
	/* Impossible to register votequorum callback */
	QDEVICE_NET_DISCONNECT_REASON_CANT_REGISTER_VOTEQUORUM_CALLBACK,
	/* Impossible to register cmap callback */
	QDEVICE_NET_DISCONNECT_REASON_CANT_REGISTER_CMAP_CALLBACK,
	/* Impossible to start TLS session */
	QDEVICE_NET_DISCONNECT_REASON_CANT_START_TLS,

	/* Received message with error field set to non TLV_REPLY_ERROR_CODE_NO_ERROR value */
	QDEVICE_NET_DISCONNECT_REASON_SERVER_SENT_ERROR,
	/* Received message with error field set to TLV_REPLY_ERROR_CODE_DUPLICATE_NODE_ID value */
	QDEVICE_NET_DISCONNECT_REASON_SERVER_SENT_DUPLICATE_NODE_ID_ERROR,
	/* Received message with error field set to TLV_REPLY_ERROR_CODE_TIE_BREAKER_DIFFERS_FROM_OTHER_NODES value */
	QDEVICE_NET_DISCONNECT_REASON_SERVER_SENT_TIE_BREAKER_DIFFERS_FROM_OTHER_NODES_ERROR,
	/* Received message with error field set to TLV_REPLY_ERROR_CODE_ALGORITHM_DIFFERS_FROM_OTHER_NODES value */
	QDEVICE_NET_DISCONNECT_REASON_SERVER_SENT_ALGORITHM_DIFFERS_FROM_OTHER_NODES_ERROR,

	/* Server doesn't support client selected decision algorithm */
	QDEVICE_NET_DISCONNECT_REASON_SERVER_DOESNT_SUPPORT_REQUIRED_ALGORITHM,
	/* Server doesn't support client required option */
	QDEVICE_NET_DISCONNECT_REASON_SERVER_DOESNT_SUPPORT_REQUIRED_OPT,

	/* Can't decode message sent by server */
	QDEVICE_NET_DISCONNECT_REASON_MSG_DECODE_ERROR,
	/* Server closed connection */
	QDEVICE_NET_DISCONNECT_REASON_SERVER_CLOSED_CONNECTION,
	/* Can't read or store message received from server */
	QDEVICE_NET_DISCONNECT_REASON_CANT_READ_MESSAGE,
	/* Can't send message to server */
	QDEVICE_NET_DISCONNECT_REASON_CANT_SEND_MESSAGE,

	/* Can't dispatch cmap or votequroum. This cannot be overwritten and always means end of qdevice-net */
	QDEVICE_NET_DISCONNECT_REASON_COROSYNC_CONNECTION_CLOSED,

	/* Local socket closed is reasult of sigint */
	QDEVICE_NET_DISCONNECT_REASON_LOCAL_SOCKET_CLOSED,

	/* It was not possible to establish connection with qnetd */
	QDEVICE_NET_DISCONNECT_REASON_CANT_CONNECT_TO_THE_SERVER,

	QDEVICE_NET_DISCONNECT_REASON_ALGO_CONNECTED_ERR,
	QDEVICE_NET_DISCONNECT_REASON_ALGO_CONFIG_NODE_LIST_CHANGED_ERR,
	QDEVICE_NET_DISCONNECT_REASON_ALGO_VOTEQUORUM_QUORUM_NOTIFY_ERR,
	QDEVICE_NET_DISCONNECT_REASON_ALGO_VOTEQUORUM_NODE_LIST_NOTIFY_ERR,
	QDEVICE_NET_DISCONNECT_REASON_ALGO_VOTEQUORUM_NODE_LIST_HEURISTICS_NOTIFY_ERR,
	QDEVICE_NET_DISCONNECT_REASON_ALGO_VOTEQUORUM_EXPECTED_VOTES_NOTIFY_ERR,
	QDEVICE_NET_DISCONNECT_REASON_ALGO_NODE_LIST_REPLY_ERR,
	QDEVICE_NET_DISCONNECT_REASON_ALGO_ASK_FOR_VOTE_REPLY_ERR,
	QDEVICE_NET_DISCONNECT_REASON_ALGO_VOTE_INFO_ERR,
	QDEVICE_NET_DISCONNECT_REASON_ALGO_ECHO_REPLY_RECEIVED_ERR,
	QDEVICE_NET_DISCONNECT_REASON_ALGO_ECHO_REPLY_NOT_RECEIVED_ERR,
	QDEVICE_NET_DISCONNECT_REASON_ALGO_HEURISTICS_CHANGE_ERR,
	QDEVICE_NET_DISCONNECT_REASON_ALGO_HEURISTICS_CHANGE_REPLY_ERR,

	QDEVICE_NET_DISCONNECT_REASON_HEURISTICS_WORKER_CLOSED,
};

#define qdevice_net_disconnect_reason_try_reconnect(reason) (						\
    reason == QDEVICE_NET_DISCONNECT_REASON_MSG_DECODE_ERROR ||						\
    reason == QDEVICE_NET_DISCONNECT_REASON_SERVER_CLOSED_CONNECTION ||					\
    reason == QDEVICE_NET_DISCONNECT_REASON_CANT_READ_MESSAGE ||					\
    reason == QDEVICE_NET_DISCONNECT_REASON_CANT_SEND_MESSAGE ||					\
    reason == QDEVICE_NET_DISCONNECT_REASON_CANT_CONNECT_TO_THE_SERVER ||				\
    reason == QDEVICE_NET_DISCONNECT_REASON_ALGO_ECHO_REPLY_NOT_RECEIVED_ERR ||				\
    reason == QDEVICE_NET_DISCONNECT_REASON_SERVER_SENT_DUPLICATE_NODE_ID_ERROR ||			\
    reason == QDEVICE_NET_DISCONNECT_REASON_SERVER_SENT_TIE_BREAKER_DIFFERS_FROM_OTHER_NODES_ERROR ||	\
    reason == QDEVICE_NET_DISCONNECT_REASON_SERVER_SENT_ALGORITHM_DIFFERS_FROM_OTHER_NODES_ERROR)


#define qdevice_net_disconnect_reason_force_disconnect(reason)	(			\
    reason == QDEVICE_NET_DISCONNECT_REASON_COROSYNC_CONNECTION_CLOSED ||		\
    reason == QDEVICE_NET_DISCONNECT_REASON_LOCAL_SOCKET_CLOSED ||			\
    reason == QDEVICE_NET_DISCONNECT_REASON_CANT_SCHEDULE_VOTING_TIMER ||		\
    reason == QDEVICE_NET_DISCONNECT_REASON_CANT_REGISTER_VOTEQUORUM_CALLBACK ||	\
    reason == QDEVICE_NET_DISCONNECT_REASON_CANT_REGISTER_CMAP_CALLBACK ||		\
    reason == QDEVICE_NET_DISCONNECT_REASON_HEURISTICS_WORKER_CLOSED)

#ifdef __cplusplus
}
#endif

#endif /* _QDEVICE_NET_DISCONNECT_REASON_H_ */
