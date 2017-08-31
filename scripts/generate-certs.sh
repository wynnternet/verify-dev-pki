#!/bin/bash
set -o errexit

# Ensure that cfssl and its related tools are on the PATH
PATH=$PATH:$GOPATH/bin/

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

# Directories we create
PKI_DIR="$ROOT_DIR/src/main/resources"
CA_CERTS_DIR="$PKI_DIR/ca-certificates"
DEV_KEYS_DIR="$PKI_DIR/dev-keys"

# Directories / files we use
CSR_TEMPLATE="$ROOT_DIR/scripts/template-csr.json"
CFSSL_CONFIG="$ROOT_DIR/scripts/cfssl-config.json"

# Recreate the directory structure
rm -rf $PKI_DIR && mkdir -p $CA_CERTS_DIR $DEV_KEYS_DIR

# Create the CA certs
cd $CA_CERTS_DIR

sed 's/$COMMON_NAME/Dev Root CA/' $CSR_TEMPLATE | cfssl genkey -initca /dev/stdin | cfssljson -bare dev-root-ca

function createInterCa {
	name=$1
	commonName=$2
	sed "s/\$COMMON_NAME/$commonName/" $CSR_TEMPLATE |
	cfssl gencert -config $CFSSL_CONFIG -profile intermediate -ca ./dev-root-ca.pem -ca-key ./dev-root-ca-key.pem /dev/stdin \
	  | cfssljson -bare $name
}
createInterCa dev-hub-ca 'Dev Hub CA'
createInterCa dev-idp-ca 'Dev IDP CA'
createInterCa dev-rp-ca 'Dev RP CA'
createInterCa dev-metadata-ca 'Dev Metadata CA'

# Add .test to all of the generated pems (to match the old file names)
for file in *.pem; do mv $file $file.test; done

# Generate leaf certs and keys

cd $DEV_KEYS_DIR
rm -f ocsp_responses

function createLeaf {
	name=$1
	ca=$2
	profile=$3
	commonName=$4
	sed "s/\$COMMON_NAME/$commonName/" $CSR_TEMPLATE |
	cfssl gencert -config $CFSSL_CONFIG -profile $profile -ca $CA_CERTS_DIR/$ca.pem.test -ca-key $CA_CERTS_DIR/$ca-key.pem.test /dev/stdin \
    | cfssljson -bare $name

  #cfssl ocspsign -ca $CA_CERTS_DIR/$ca.pem.test -cert ${name}.pem | cfssljson -bare -stdout >> ocsp_responses
}
createLeaf metadata_signing_a                 dev-metadata-ca  signing       'Dev Metadata Signing A'
createLeaf metadata_signing_b                 dev-metadata-ca  signing       'Dev Metadata Signing B'
createLeaf hub_signing_primary                dev-hub-ca       signing       'Dev Hub Signing'
createLeaf hub_encryption_primary             dev-hub-ca       encipherment  'Dev Hub Encryption'
createLeaf sample_rp_encryption_primary       dev-rp-ca        encipherment  'Dev Sample RP Encryption'
createLeaf sample_rp_msa_encryption_primary   dev-rp-ca        encipherment  'Dev Sample RP MSA Encryption'
createLeaf sample_rp_msa_signing_primary      dev-rp-ca        signing       'Dev Sample RP MSA Signing'
createLeaf sample_rp_signing_primary          dev-rp-ca        signing       'Dev Sample RP Signing'
createLeaf stub_idp_signing_primary           dev-idp-ca       signing       'Dev Stub IDP Signing'
createLeaf hub_signing_secondary              dev-hub-ca       signing       'Dev Hub Signing 2'
createLeaf hub_encryption_secondary           dev-hub-ca       encipherment  'Dev Hub Encryption 2'
createLeaf sample_rp_encryption_secondary     dev-rp-ca        encipherment  'Dev Sample RP Encryption 2'
createLeaf sample_rp_msa_encryption_secondary dev-rp-ca        encipherment  'Dev Sample RP MSA Encryption 2'
createLeaf sample_rp_msa_signing_secondary    dev-rp-ca        signing       'Dev Sample RP MSA Signing 2'
createLeaf sample_rp_signing_secondary        dev-rp-ca        signing       'Dev Sample RP Signing 2'
createLeaf stub_idp_signing_secondary         dev-idp-ca       signing       'Dev Stub IDP Signing 2'

# Convert all the keys to .pk8 files
for file in *-key.pem
do
  openssl pkcs8 -topk8 -inform PEM -outform DER -in $file -out ${file%-key.pem}.pk8 -nocrypt
done

# Remove the files we no longer need
rm *.csr *-key.pem

# Rename the pem files to .crt (to match old file names)
for file in *.pem; do mv $file ${file%.pem}.crt; done

# Remove the files we no longer need
cd $CA_CERTS_DIR
rm *.csr *-key.pem.test

