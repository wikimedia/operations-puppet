#!/bin/bash

function generate_ca_and_cert() {
    local NAME_CA=$1
    local CADAYS=$2
    local CERT_NAME=$3
    local CERTDAYS=$4
    local OUTDIR=$5


    openssl ecparam -genkey -name secp256r1 2> /dev/null | openssl ec -out $OUTDIR/${NAME_CA}.key &> /dev/null
    openssl req -new -x509 -subj "/C=US/ST=CA/O=MyOrg, Inc./CN=mydomain.com" -days ${CADAYS} -key $OUTDIR/${NAME_CA}.key -out $OUTDIR/${NAME_CA}.pem &> /dev/null

    openssl ecparam -genkey -name secp256r1  2> /dev/null | openssl ec -out $OUTDIR/${CERT_NAME}.key &> /dev/null
    openssl req -new  -subj "/C=US/ST=CA/O=MyOrg, Inc./CN=mydomain.com" -key $OUTDIR/${CERT_NAME}.key -out $OUTDIR/${CERT_NAME}.csr &> /dev/null
    openssl x509 -req -days ${CERTDAYS} -in $OUTDIR/${CERT_NAME}.csr -CA $OUTDIR/${NAME_CA}.pem -CAkey $OUTDIR/${NAME_CA}.key -set_serial 1 -out $OUTDIR/${CERT_NAME}.pem &> /dev/null
}

function main {
    generate_ca_and_cert 1_expired_ca 1 1_valid_cert 30000 $1
    generate_ca_and_cert 2_valid_ca 30000 2_valid_cert 30000 $1
    generate_ca_and_cert 3_valid_ca 30000 3_expired_cert 0 $1
    generate_ca_and_cert 4_expired_ca 1 4_expired_cert 0 $1
}

main $1
