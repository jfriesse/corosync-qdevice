#!@BASHPATH@

#
# Copyright (c) 2015-2026 Red Hat, Inc.
#
# All rights reserved.
#
# Author: Jan Friesse (jfriesse@redhat.com)
#
# This software licensed under BSD license, the text of which follows:
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# - Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# - Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# - Neither the name of the Red Hat, Inc. nor the names of its
#   contributors may be used to endorse or promote products derived from this
#   software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
# THE POSSIBILITY OF SUCH DAMAGE.
#

BASE_DIR="@COROSYSCONFDIR@/qdevice/net"
DB_DIR_QNETD="@COROSYSCONFDIR@/qnetd/nssdb"
DB_DIR="$BASE_DIR/nssdb"
CA_NICKNAME="QNet CA"
CLUSTER_NICKNAME="Cluster Cert"
PWD_FILE="$DB_DIR/pwdfile.txt"
NOISE_FILE="$DB_DIR/noise.txt"
CA_EXPORT_BASE="qnetd-cacert.crt"
CA_EXPORT_FILE="$DB_DIR_QNETD/$CA_EXPORT_BASE"
CRQ_FILE_BASE="qdevice-net-node.crq"
CRQ_FILE="$DB_DIR/$CRQ_FILE_BASE"
P12_FILE_BASE="qdevice-net-node.p12"
P12_FILE="$DB_DIR/$P12_FILE_BASE"
QNETD_CERTUTIL_CMD="corosync-qnetd-certutil"
CERTDB_FILES=("cert9.db key4.db pkcs11.txt"
              "cert8.db key3.db secmod.db")
REMOTE_SHELL_EXECUTABLE="ssh"
REMOTE_COPY_EXECUTABLE="scp"

# errx exit_code message
errx() {
    echo "$2" >&2

    exit "$1"
}

usage() {
    echo "$0: [-i|-M|-m|-Q|-r] [-C scp_command] [-c certificate] [-g keysize] [-k keytype] [-n cluster_name] [-S ssh_command] [-q paramset]"
    echo
    echo " -i      Initialize node CA. Needs CA certificate from server"
    echo " -M      Import signed cluster certificate and export certificate with key to pk12 file"
    echo " -m      Import cluster certificate on node (needs pk12 certificate)"
    echo " -Q      Quick start. Uses ssh/scp to initialze both qnetd and nodes."
    echo " -r      Generate cluster certificate request"
    echo ""
    echo " -C scp_command      Alternative remote copy command to be use in place of scp. If not specified, scp is used."
    echo " -c certificate      Ether CA, CRQ, CRT or pk12 certificate (operation dependant)"
    echo " -g keysize          Key size in bits - passed directly to certutil as -g parameter"
    echo " -k keytype          Type of key - passed directly to certutil as -k parameter"
    echo " -n cluster_name     Name of cluster (for -r and -s operations)"
    echo " -S ssh_command      Alternative remote shell command to be use in place of ssh. If not specified, ssh is used."
    echo " -q paramset         Parameter set (curve name, ml-dsa set) - passed directly to certutil as -q parameter"
    echo ""
    echo "Typical usage:"
    echo "- Initialize database on QNetd server by running $QNETD_CERTUTIL_CMD -i"
    echo "- Copy exported QNetd CA certificate ($CA_EXPORT_FILE) to every node"
    echo "- On one of cluster node initialize database by running $0 -i -c $CA_EXPORT_BASE"
    echo "- Generate certificate request: $0 -r -n Cluster (Cluster name must match cluster_name key in the corosync.conf)"
    echo "- Copy exported CRQ to QNetd server"
    echo "- On QNetd server sign and export cluster certificate by running $QNETD_CERTUTIL_CMD -s -c $CRQ_FILE_BASE -n Cluster"
    echo "- Copy exported CRT to node where certificate request was created"
    echo "- Import certificate on node where certificate request was created by running $0 -M -c cluster-Cluster.crt"
    echo "- Copy output $P12_FILE_BASE to all other cluster nodes"
    echo "- On all other nodes in cluster:"
    echo "  - Init database by running $0 -i -c $CA_EXPORT_BASE"
    echo "  - Import cluster certificate and key: $0 -m -c $P12_FILE_BASE"
    echo ""
    echo "It is also possible to use Quick start (-Q). This needs properly configured remote shell command and remote copy command (ssh and scp by default)."
    echo "  $0 -Q [-S ssh_command] [-C scp_command] -n Cluster qnetd_server node1 node2 ... nodeN"

    exit 0
}

get_certutil_key_params() {
    CERTUTIL_PARAMS=""

    if [ ! -z "$COROSYNC_QDEVICE_NET_CERTUTIL_KEY_SIZE" ];then
        CERTUTIL_PARAMS="$CERTUTIL_PARAMS -g $COROSYNC_QDEVICE_NET_CERTUTIL_KEY_SIZE"
    fi

    if [ ! -z "$COROSYNC_QDEVICE_NET_CERTUTIL_KEY_TYPE" ];then
        CERTUTIL_PARAMS="$CERTUTIL_PARAMS -k $COROSYNC_QDEVICE_NET_CERTUTIL_KEY_TYPE"
    fi

    if [ ! -z "$COROSYNC_QDEVICE_NET_CERTUTIL_PARAMSET" ];then
        CERTUTIL_PARAMS="$CERTUTIL_PARAMS -q $COROSYNC_QDEVICE_NET_CERTUTIL_PARAMSET"
    fi

    echo "$CERTUTIL_PARAMS"
}

create_new_noise_file() {
    local noise_file="$1"

    if [ ! -e "$noise_file" ];then
        echo "Creating new noise file $noise_file"

        (ps -elf; date; w) | sha1sum | (read sha_sum rest; echo $sha_sum) > "$noise_file"

        chown root:root "$noise_file"
        chmod 0660 "$noise_file"
    else
        echo "Using existing noise file $noise_file"
    fi
}

find_certdb_files() {
    for cert_files_index in "${!CERTDB_FILES[@]}";do
        cert_files=${CERTDB_FILES[$cert_files_index]}
        test_file=${cert_files%% *}
        if [ -f "$DB_DIR/$test_file" ];then
            echo "$cert_files"

            return 0
        fi
    done
}

init_node_ca() {
    cert_files=`find_certdb_files`
    if [ "$cert_files" != "" ];then
        errx 1 "Certificate database already exists. Delete it to continue"
    fi

    if ! [ -d "$DB_DIR" ];then
        echo "Creating $DB_DIR"
        mkdir -p "$DB_DIR"
        chown root:root "$DB_DIR"
        chmod 0770 "$DB_DIR"
    fi

    echo "Creating new key and cert db"
    echo -n "" > "$PWD_FILE"
    chown root:root "$PWD_FILE"
    chmod 0660 "$PWD_FILE"
    certutil -N -d "$DB_DIR" -f "$PWD_FILE"
    cert_files=`find_certdb_files`
    if [ "$cert_files" == "" ];then
        errx 1 "Can't find certificate database files. Certificate database ($DB_DIR) cannot be created"
    fi

    for fname in $cert_files;do
        chown root:root "$DB_DIR/$fname"
        chmod 0660 "$DB_DIR/$fname"
    done

    create_new_noise_file "$NOISE_FILE"

    echo "Importing CA"

    certutil -d "$DB_DIR" -A -t "CT,c,c" -n "$CA_NICKNAME" -f "$PWD_FILE" \
        -i "$CERTIFICATE_FILE"
}

gen_cluster_cert_req() {
    cert_files=`find_certdb_files`
    if [ "$cert_files" == "" ];then
        errx 1 "Certificate database doesn't exists. Use $0 -i to create it"
    fi

    echo "Creating new certificate request"

    certutil -R -s "CN=$CLUSTER_NAME" -o "$CRQ_FILE" -d "$DB_DIR" -f "$PWD_FILE" -z "$NOISE_FILE" \
        $(get_certutil_key_params)

    echo "Certificate request stored in $CRQ_FILE"
}

import_signed_cert() {
    cert_files=`find_certdb_files`
    if [ "$cert_files" == "" ];then
        errx 1 "Certificate database doesn't exists. Use $0 -i to create it"
    fi

    echo "Importing signed cluster certificate"
    certutil -d "$DB_DIR" -A -t "u,u,u" -n "$CLUSTER_NICKNAME" -i "$CERTIFICATE_FILE"

    pk12util -d "$DB_DIR" -o "$P12_FILE" -W "" -n "$CLUSTER_NICKNAME"

    echo "Certificate stored in $P12_FILE"
}

import_pk12() {
    cert_files=`find_certdb_files`
    if [ "$cert_files" == "" ];then
        errx 1 "Certificate database doesn't exists. Use $0 -i to create it"
    fi

    echo "Importing cluster certificate and key"
    pk12util -i "$CERTIFICATE_FILE" -d "$DB_DIR" -W ""
}

# Wrapper on top of scp which first copies (scp) file to local machine saving to
# temporary file and then copies to another remote machine. Standard scp doesn't
# handle situation with two hosts in one command very well when agent forwarding
# is used and there is no key between two machines.
remote_scp() {
    tmp_file=`mktemp`

    $REMOTE_COPY_EXECUTABLE "$1" "$tmp_file"
    $REMOTE_COPY_EXECUTABLE "$tmp_file" "$2"

    rm -f "$tmp_file"
}

quick_start() {
    qnetd_addr="$1"
    master_node="$2"
    other_nodes="$3"

    # Sanity check
    for i in "$master_node" $other_nodes;do
        if $REMOTE_SHELL_EXECUTABLE root@$i "[ -d \"$DB_DIR\" ]";then
            errx 1 "Node $i seems to be already initialized. Please delete $DB_DIR"
        fi

        if ! $REMOTE_SHELL_EXECUTABLE "root@$i" "$0" > /dev/null;then
            errx 1 "Node $i doesn't have $0 installed"
        fi
    done

    # Initialize qnetd server (it's no problem if server is already initialized)
    $REMOTE_SHELL_EXECUTABLE "root@$qnetd_addr" "$QNETD_CERTUTIL_CMD -i" || true

    # Copy CA cert to all nodes and initialize them
    for node in "$master_node" $other_nodes;do
        remote_scp "root@$qnetd_addr:$CA_EXPORT_FILE" "root@$node:/tmp/$CA_EXPORT_BASE"
        $REMOTE_SHELL_EXECUTABLE "root@$node" "$0 -i -c \"/tmp/$CA_EXPORT_BASE\" && rm /tmp/$CA_EXPORT_BASE"
    done

    # Generate cert request
    $REMOTE_SHELL_EXECUTABLE "root@$master_node" "$0 -r -n \"$CLUSTER_NAME\""

    # Copy exported cert request to qnetd server
    remote_scp "root@$master_node:$CRQ_FILE" "root@$qnetd_addr:/tmp/$CRQ_FILE_BASE"

    # Sign and export cluster certificate
    $REMOTE_SHELL_EXECUTABLE "root@$qnetd_addr" "$QNETD_CERTUTIL_CMD -s -c \"/tmp/$CRQ_FILE_BASE\" -n \"$CLUSTER_NAME\""

    # Copy exported CRT to master node
    remote_scp "root@$qnetd_addr:$DB_DIR_QNETD/cluster-$CLUSTER_NAME.crt" \
        "root@$master_node:$DB_DIR/cluster-$CLUSTER_NAME.crt"

    # Import certificate
    $REMOTE_SHELL_EXECUTABLE "root@$master_node" "$0 -M -c \"$DB_DIR/cluster-$CLUSTER_NAME.crt\""

    # Copy pk12 cert to all nodes and import it
    for node in $other_nodes;do
        remote_scp "root@$master_node:$P12_FILE" "$node:$P12_FILE"

        # Ignore import errors (no easy way to remove "improperly formatted DER-encoded" message
        # resulting in error code != 0 but successful import)
        $REMOTE_SHELL_EXECUTABLE "root@$node" "$0 -m -c \"$P12_FILE\"" || true
    done
}

# Initialize options that may be overwritten by the configuration file
COROSYNC_QDEVICE_NET_CERTUTIL_KEY_SIZE=""
COROSYNC_QDEVICE_NET_CERTUTIL_KEY_TYPE=""
COROSYNC_QDEVICE_NET_CERTUTIL_PARAMSET=""

# Import configuration file if it exists
if [ -f "@INITCONFIGDIR@/corosync-qdevice" ];then
    . "@INITCONFIGDIR@/corosync-qdevice"
fi

# Strict mode
set -euo pipefail
trap 's=$?; echo >&2 "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

OPERATION=""
CERTIFICATE_FILE=""
CLUSTER_NAME=""

while getopts ":hiMmQrC:c:g:k:n:S:q:" opt; do
    case $opt in
        i)
            OPERATION=init_node_ca
            ;;
        M)
            OPERATION=import_signed_cert
            ;;
        m)
            OPERATION=import_pk12
            ;;
        Q)
            OPERATION=quick_start
            ;;
        r)
            OPERATION=gen_cluster_cert_req
            ;;
        h)
            usage
            ;;
        C)
            REMOTE_COPY_EXECUTABLE="$OPTARG"
            ;;
        c)
            CERTIFICATE_FILE="$OPTARG"
            ;;
        g)
            COROSYNC_QDEVICE_NET_CERTUTIL_KEY_SIZE="$OPTARG"
            ;;
        k)
            COROSYNC_QDEVICE_NET_CERTUTIL_KEY_TYPE="$OPTARG"
            ;;
        n)
            CLUSTER_NAME="$OPTARG"
            ;;
        S)
            REMOTE_SHELL_EXECUTABLE="$OPTARG"
            ;;
        q)
            COROSYNC_QDEVICE_NET_CERTUTIL_PARAMSET="$OPTARG"
            ;;
        \?)
            errx 1 "Invalid option: -$OPTARG"
            ;;
        :)
            errx 1 "Option -$OPTARG requires an argument."
            ;;
   esac
done

[ "$OPERATION" == "" ] && usage

case "$OPERATION" in
    "init_node_ca")
        if ! [ -e "$CERTIFICATE_FILE" ];then
            errx 2 "Can't open certificate file $CERTIFICATE_FILE"
        fi

        init_node_ca
    ;;
    "gen_cluster_cert_req")
        if [ "$CLUSTER_NAME" == "" ];then
            errx 2 "You have to specify cluster name"
        fi

        gen_cluster_cert_req
    ;;
    "import_signed_cert")
        if ! [ -e "$CERTIFICATE_FILE" ];then
            errx 2 "Can't open certificate file $CERTIFICATE_FILE"
        fi

        import_signed_cert
    ;;
    "import_pk12")
        if ! [ -e "$CERTIFICATE_FILE" ];then
            errx 2 "Can't open certificate file $CERTIFICATE_FILE"
        fi

        import_pk12
    ;;
    "quick_start")
        shift $((OPTIND-1))

        if [ "$CLUSTER_NAME" == "" ];then
            errx 2 "You have to specify cluster name"
        fi

        qnetd_addr=${1:-}
        if [ "$qnetd_addr" == "" ];then
            errx 2 "No QNetd server address provided."
        fi

        shift 1

        master_node=${1:-}
        if [ "$master_node" == "" ];then
            errx 2 "No nodes provided."
        fi

        shift 1
        other_nodes="$*"

        quick_start "$qnetd_addr" "$master_node" "$other_nodes"
    ;;
    *)
        usage
    ;;
esac
