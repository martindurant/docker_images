#!/bin/bash
# See http://pki-tutorial.readthedocs.io/en/latest/simple/

set -e
set -o xtrace

CONF=${PWD}
OUTDIR=~/keys
CONDA_PREFIX=/opt/conda

mkdir -p ${OUTDIR}
cd ${OUTDIR}


function create_root_ca() {
    # 1.1 Create directories
    mkdir -p ca/root-ca/private ca/root-ca/db crl certs

    if [ ! -f ca/root-ca/db/root-ca.db ]; then
        # 1.2 Create database
        cp /dev/null ca/root-ca/db/root-ca.db
        cp /dev/null ca/root-ca/db/root-ca.db.attr
        echo 01 > ca/root-ca/db/root-ca.crt.srl
        echo 01 > ca/root-ca/db/root-ca.crl.srl
    fi

    KEYPATH=${PWD}/ca/root-ca/private/root-ca.key

    if [ ! -f ${KEYPATH} ]; then
        # 1.3 Create CA request
        openssl req -new \
            -config ${CONF}/root-ca.conf \
            -out ca/root-ca.csr \
            -keyout ${KEYPATH} \
            -passout pass:continuum
        echo "Created root CA key in ${KEYPATH}"
    else
        echo "Existing root CA key in ${KEYPATH}"
    fi

    CERTPATH=${PWD}/ca/root-ca.crt

    if [ ! -f ${CERTPATH} ]; then
        # 1.4 Create CA certificate
        openssl ca -selfsign \
            -config ${CONF}/root-ca.conf \
            -batch \
            -in ca/root-ca.csr \
            -passin pass:continuum \
            -out ${CERTPATH} \
            -extensions root_ca_ext
        echo "Created root CA certificate in ${CERTPATH}"
    else
        echo "Existing root CA certificate in ${CERTPATH}"
    fi
}


function create_signing_ca() {
    # 2.1 Create directories
    # The ca directory holds CA resources, the crl directory holds CRLs,
    # and the certs directory holds user certificates.

    mkdir -p ca/signing-ca/private ca/signing-ca/db crl certs
    chmod 700 ca/signing-ca/private

    # 2.2 Create database
    if [ ! -f ca/signing-ca/db/signing-ca.db ]; then
        cp /dev/null ca/signing-ca/db/signing-ca.db
        cp /dev/null ca/signing-ca/db/signing-ca.db.attr
        echo 01 > ca/signing-ca/db/signing-ca.crt.srl
        echo 01 > ca/signing-ca/db/signing-ca.crl.srl
    fi

    # 2.3 Create CA request
    # TODO prevent prompting for password
    KEYPATH=${PWD}/ca/signing-ca/private/signing-ca.key

    if [ ! -f ${KEYPATH} ]; then
        openssl req -new \
            -config ${CONF}/signing-ca.conf \
            -out ca/signing-ca.csr \
            -keyout ${KEYPATH} \
            -passout pass:continuum
        echo "Created signing CA key in ${KEYPATH}"
    else
        echo "Existing signing CA key in ${KEYPATH}"
    fi

    # 2.4 Create CA certificate
    CERTPATH=${PWD}/ca/signing-ca.crt

    if [ ! -f ${CERTPATH} ]; then
        openssl ca \
            -config ${CONF}/root-ca.conf \
            -batch \
            -in ca/signing-ca.csr \
            -passin pass:continuum \
            -out ${CERTPATH} \
            -extensions signing_ca_ext
        echo "Created signing CA certificate in ${CERTPATH}"
    else
        echo "Existing signing CA certificate in ${CERTPATH}"
    fi

    # 4.5 Create PEM bundle
    CA_CHAIN=${PWD}/certs/ca-chain.pem

    if [ ! -f ${CA_CHAIN} ]; then
        cat ${CERTPATH} ca/root-ca.crt $CONDA_PREFIX/ssl/cacert.pem > certs/ca-chain.pem
        echo "Created CA certificate chain in ${CA_CHAIN}"
    else
        filesize=$(wc -c <"${CA_CHAIN}")
        if [ $filesize -lt 20000 ]; then
            echo "Existing CA certificate chain doesn't contain OpenSSL default; adding them"
            cat ${CERTPATH} ca/root-ca.crt $CONDA_PREFIX/ssl/cacert.pem > certs/ca-chain.pem
        fi
        echo "Existing CA certificate chain in ${CA_CHAIN}"
    fi

}

function gen_key_and_cert() {
    # 3.3 Create TLS server request
    if [ ! -f certs/$1.key ]; then
        openssl req -new \
            -config ${CONF}/$1.conf \
            -out certs/$1.csr \
            -keyout certs/$1.key
        echo "Created key for $1 in certs/$1.key"
    else
        echo "Existing key for $1 in certs/$1.key"
    fi


    # 3.4 Create TLS server certificate
    if [ ! -f certs/$1.crt ]; then
        openssl ca \
            -config ${CONF}/signing-ca.conf \
            -batch \
            -in certs/$1.csr \
            -passin pass:continuum \
            -out certs/$1.crt \
            -extensions server_ext
        echo "Created cert for $1 in certs/$1.crt"
    else
        echo "Existing cert for $1 in certs/$1.crt"
    fi
}


function create_java_keystore() {
    # import the signed cert back into the keystore $NAME.jks
    if [ ! -f $1.p12 ]; then
        openssl pkcs12 -export \
            -in certs/$1.crt \
            -inkey certs/$1.key \
            -chain \
            -CAfile certs/ca-chain.pem \
            -name $1 \
            -out $1.p12 \
            -passout pass:continuum
    fi

    if [ ! -f certs/$1.jks ]; then
        keytool -importkeystore \
            -srckeystore $1.p12 \
            -srcstoretype PKCS12 \
            -srcstorepass continuum \
            -destkeystore certs/$1.jks \
            -deststorepass continuum
        echo "Created Java keystore for $1 in ${PWD}/$1.jks"
    else
        echo "Existing Java keystore for $1 in ${PWD}/$1.jks"
    fi

}

create_root_ca
create_signing_ca

gen_key_and_cert auth

create_java_keystore auth

# verify that all certs can be validated if we trust the root key
openssl verify -verbose -CAfile certs/ca-chain.pem certs/*.crt
