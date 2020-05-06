#!/bin/bash

#
# request and sign a generic x509 TLS cert from the kubernetes API.
# This script must be run as root in any k8s control node.
#
# For usage try -h/--help
#

set -e
usage() {
    echo "INFO: Usage of this script:"
    echo -e "      $0 -h/--help   \t- show help and exit"
    echo -e "      $0 <svcname>   \t- generate a x509 TLS cert from the kubernetes API"
    echo -e "      $0 <svcname> -v\t- same, but in verbose mode"
}

usage_error() {
    echo "ERROR: wrong arguments. Try -h/--help" >&2
    exit 1
}

# this includes -h/--help and prevents --whatever to reach
# the kubectl input
if [[ "$1" =~ ^"-" ]] ; then
    usage
    exit 0
fi

title="$1"
if [ -z "$title" ] ; then
    usage_error
fi

verbose="$2"
if [ ! -z "$verbose" ] && [ "$verbose" != "-v" ] ; then
    usage_error
fi

exec 3>/dev/stdout
if [ "$verbose" != "-v" ] ; then
     exec &>/dev/null
fi

if [ "$(id -u)" != "0" ] ; then
    echo "ERROR: are you running this script as root in a k8s control node?" >&2
    exit 1
fi

csrName=${title}
tmpdir=$(mktemp -d)
[ "$verbose" == "-v" ] && echo "INFO: creating certs in tmpdir ${tmpdir}"

cat <<EOF >> ${tmpdir}/csr.conf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${title}
DNS.2 = ${title}.${title}
DNS.3 = ${title}.${title}.svc
EOF

openssl genrsa -out ${tmpdir}/server-key.pem 2048
openssl req -new -key ${tmpdir}/server-key.pem -subj "/CN=${title}" -out ${tmpdir}/server.csr -config ${tmpdir}/csr.conf

# clean-up any previously created CSR for our service. Ignore errors if not present.
kubectl delete csr ${csrName} || true

# create  server cert/key CSR and  send to k8s API
cat <<EOF | kubectl create -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: ${csrName}
spec:
  groups:
  - system:authenticated
  request: $(cat ${tmpdir}/server.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
  - client auth
EOF

# verify CSR has been created
while true; do
    kubectl get csr ${csrName}
    if [ "$?" -eq 0 ]; then
        break
    fi
done

# approve and fetch the signed certificate
kubectl certificate approve ${csrName}
# verify certificate has been signed
for x in $(seq 10); do
    serverCert=$(kubectl get csr ${csrName} -o jsonpath='{.status.certificate}')
    if [[ ${serverCert} != '' ]]; then
        break
    fi
    sleep 1
done
if [[ ${serverCert} == '' ]]; then
    echo "ERROR: After approving csr ${csrName}, the signed certificate did not appear on the resource. Giving up after 10 attempts." >&2
    exit 1
fi
echo ${serverCert} | openssl base64 -d -A -out ${tmpdir}/server-cert.pem

if [ "$verbose" == "-v" ] ; then
    echo
    echo "INFO: your TLS cert files are:"
    echo "INFO:     ${tmpdir}/server-cert.pem"
    echo "INFO:     ${tmpdir}/server-key.pem"
else
    echo "${tmpdir}/server-cert.pem" >&3
    echo "${tmpdir}/server-key.pem" >&3
fi
