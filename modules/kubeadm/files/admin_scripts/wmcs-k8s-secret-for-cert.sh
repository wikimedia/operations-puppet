#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

set -e
usage() {
    echo "INFO: this script creates a k8s secret to hold a x509 cert for a"
    echo "      given service account (pub/priv) which you can then use inside"
    echo "      a pod, mounting the secret as a volume. Usage:"
    echo ""
    echo "  $0 [-n <namespace>] -s <secretname> -a <svcname> [-v] | -h"
    echo ""
    echo "    -n namespace    the namespace in which the secret will be created (uses default if not specified)."
    echo "    -s secretname   name of the secret being created. This is the name you use to mount it later on."
    echo "    -a svcname      service name, doing RBAC auth for this service account."
    echo "    -v              verbose mode."
    echo ""
    echo "    -h              show help and exit."
    exit 0
}

usage_error() {
    echo "ERROR: wrong arguments. Try -h" >&2
    exit 1
}

while getopts ":hvn:s:a:" o; do
    case "${o}" in
        n)
            namespace=${OPTARG}
            ;;
        s)
            secretname=${OPTARG}
            ;;
        a)
            svcname=${OPTARG}
            ;;
        v)
            verbose="v"
            ;;
        h)
            usage
            ;;
        *)
            usage_error
            ;;
    esac
done

if [ -z "$namespace" ] ; then
    namespace="default"
fi

if [ -z "$svcname" ] ; then
    echo "ERROR: no service name account specified. Try -h" >&2
    exit 1
fi

if [ -z "$secretname" ] ; then
    echo "ERROR: no secret name specified. Try -h" >&2
    exit 1
fi

if [ "$(id -u)" != "0" ] ; then
    echo "ERROR: root required" >&2
    exit 1
fi

WMCS_K8S_GET_CERT=$(which wmcs-k8s-get-cert)
if [ ! -x "$WMCS_K8S_GET_CERT" ] ; then
    echo "ERROR: no wmcs-k8s-get-cert script found. We need it to generate the x509 certs." >&2
    exit 1
fi

KUBECTL=$(which kubectl)
if [ ! -x "$KUBECTL" ] ; then
    echo "ERROR: no kubectl binary found. We need it to interact with the k8s API." >&2
    exit 1
fi

cmd="${WMCS_K8S_GET_CERT} ${svcname}"
[ "$verbose" == "v" ] && echo "INFO: executing '${cmd}'"
GET_CERT_OUTPUT="$(eval ${cmd})"
[ "$verbose" == "v" ] && echo "$GET_CERT_OUTPUT"

if [ "$(wc -l <<< ${GET_CERT_OUTPUT})" != 2 ] ; then
    echo  "ERROR: something went wrong when generating the cert via $WMCS_K8S_GET_CERT" >&2
    exit 1
fi

TEMP_CRT_FILE="$(head -1 <<< ${GET_CERT_OUTPUT})"
TEMP_KEY_FILE="$(tail -1 <<< ${GET_CERT_OUTPUT})"

if [ "$(grep -c server-cert.pem$ <<< $TEMP_CRT_FILE)" != "1" ] ; then
    echo "ERROR: something went wrong. I can't undestand the output (cert) of $WMCS_K8S_GET_CERT" >&2
    exit 1
fi

if [ "$(grep -c server-key.pem$ <<< $TEMP_KEY_FILE)" != "1" ] ; then
    echo "ERROR: something went wrong. I can't undestand the output (key) of $WMCS_K8S_GET_CERT" >&2
    exit 1
fi

if [ ! -r "$TEMP_KEY_FILE" ] ; then
    echo "ERROR: something went wrong when generating the cert. I cannot read $TEMP_KEY_FILE" >&2
    exit 1
fi

if [ ! -r "$TEMP_CRT_FILE" ] ; then
    echo "ERROR: something went wrong when generating the cert. I cannot read $TEMP_CRT_FILE" >&2
    exit 1
fi

# finally!

cmd="${KUBECTL} create secret generic ${secretname}
 --from-file=key.pem=${TEMP_KEY_FILE}
 --from-file=cert.pem=${TEMP_CRT_FILE}
 --dry-run -o yaml"
[ "$verbose" == "v" ] && echo -e "\nINFO: executing '${cmd}'"
CREATE_SECRET_OUTPUT="$(eval ${cmd})"
[ "$verbose" == "v" ] && echo -e "${CREATE_SECRET_OUTPUT}"


cmd="${KUBECTL} apply -n ${namespace} -f -"
[ "$verbose" == "v" ] && echo -e "\nINFO: executing '${cmd}'"
echo "${CREATE_SECRET_OUTPUT}" | ${cmd}

rm -f $TEMP_CRT_FILE
rm -f $TEMP_KEY_FILE
