#!/usr/bin/env bash

set -o errexit

createTruststore () {
  local store="$1"
  local pass="marshmallow"

  shift 1
  local certs="$@"
  
  for name in $certs; do
    cert="src/main/resources/ca-certificates/${name}.pem.test"
    keytool -import -noprompt -alias "$name" -file "$cert" -keystore "truststores/${store}.ts" -storepass "$pass"
  done

  keytool -list -storepass "$pass" -keystore "truststores/${store}.ts"
}

mkdir -p truststores
rm -f truststores/*.ts

createTruststore identity_providers dev-root-ca dev-idp-ca
createTruststore relying_parties    dev-root-ca dev-rp-ca
createTruststore metadata           dev-root-ca dev-metadata-ca
