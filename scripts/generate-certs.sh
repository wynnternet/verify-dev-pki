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

sed 's/$COMMON_NAME/IDAP Dev Root CA/' $CSR_TEMPLATE | cfssl genkey -initca /dev/stdin | cfssljson -bare ida-root-ca

function createInterCa {
	name=$1
	commonName=$2
	sed "s/\$COMMON_NAME/$commonName/" $CSR_TEMPLATE |
	cfssl gencert -config $CFSSL_CONFIG -profile intermediate -ca ./ida-root-ca.pem -ca-key ./ida-root-ca-key.pem /dev/stdin |
	cfssljson -bare $name
}
createInterCa idap-core-ca 'IDAP Core CA Dev'
createInterCa ida-intermediary-ca 'IDA Inter CA Dev'
createInterCa ida-intermediary-rp-ca 'IDA Inter RP CA Dev'
createInterCa ida-metadata-ca 'IDA Metadata CA Dev'

# Add .test to all of the generated pems (to match the old file names)
for file in *.pem; do mv $file $file.test; done

# Generate leaf certs and keys

cd $DEV_KEYS_DIR

function createLeaf {
	name=$1
	ca=$2
	profile=$3
	commonName=$4
	sed "s/\$COMMON_NAME/$commonName/" $CSR_TEMPLATE |
	cfssl gencert -config $CFSSL_CONFIG -profile $profile -ca $CA_CERTS_DIR/$ca.pem.test -ca-key $CA_CERTS_DIR/$ca-key.pem.test /dev/stdin |
	cfssljson -bare $name
}
createLeaf metadata_signing_a                 ida-metadata-ca        signing            'IDA Metadata Signing Dev A'
createLeaf metadata_signing_b                 ida-metadata-ca        signing            'IDA Metadata Signing Dev B'
createLeaf hub_signing_primary                idap-core-ca           signing            'IDA Hub Signing Dev'
createLeaf hub_encryption_primary             idap-core-ca           encipherment       'IDA Hub Encryption Dev'
createLeaf hub_connector_signing_primary      idap-core-ca           signing            'IDA Connector Hub Signing Dev'
createLeaf hub_connector_encryption_primary   idap-core-ca           encipherment       'IDA Connector Hub Encryption Dev'
createLeaf sample_rp_encryption_primary       ida-intermediary-rp-ca encipherment       'IDA Sample RP Encryption Dev'
createLeaf sample_rp_msa_encryption_primary   ida-intermediary-rp-ca encipherment       'IDA Sample RP MSA Encryption Dev'
createLeaf sample_rp_msa_signing_primary      ida-intermediary-rp-ca signing            'IDA Sample RP MSA Signing Dev'
createLeaf sample_rp_signing_primary          ida-intermediary-rp-ca signing            'IDA Sample RP Signing Dev'
createLeaf stub_idp_signing_primary           ida-intermediary-ca    signing            'IDA Stub IDP Signing Dev'
createLeaf stub_country_signing_primary       ida-intermediary-ca    signing            'IDA Stub Country Signing Dev'
createLeaf hub_signing_secondary              idap-core-ca           signing            'IDA Hub Signing Dev'
createLeaf hub_encryption_secondary           idap-core-ca           encipherment       'IDA Hub Encryption Dev'
createLeaf sample_rp_encryption_secondary     ida-intermediary-rp-ca encipherment       'IDA Sample RP Encryption Dev'
createLeaf sample_rp_msa_encryption_secondary ida-intermediary-rp-ca encipherment       'IDA Sample RP MSA Encryption Dev'
createLeaf sample_rp_msa_signing_secondary    ida-intermediary-rp-ca signing            'IDA Sample RP MSA Signing Dev'
createLeaf sample_rp_signing_secondary        ida-intermediary-rp-ca signing            'IDA Sample RP Signing Dev'
createLeaf stub_idp_signing_secondary         ida-intermediary-ca    signing            'IDA Stub IDP Signing Dev'
createLeaf stub_country_signing_secondary     ida-intermediary-ca    signing            'IDA Stub Country Signing Dev'
createLeaf stub_country_signing_tertiary      ida-intermediary-ca    signing_low_date   'IDA Stub Country Signing Dev'

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

