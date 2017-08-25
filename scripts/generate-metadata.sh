#!/usr/bin/env bash

sources="$PWD/metadata"
output="$PWD/metadata/output"
cadir="$PWD/src/main/resources/ca-certificates"
certdir="$PWD/src/main/resources/dev-keys"

mkdir -p "$output"

# generate
bundle
bundle exec generate_metadata -c "$sources" -e dev -w -o "$output" \
  --hubCA "$cadir"/dev-root-ca.pem.test \
  --hubCA "$cadir"/dev-hub-ca.pem.test \
  --idpCA "$cadir"/dev-root-ca.pem.test \
  --idpCA "$cadir"/dev-idp-ca.pem.test

# sign
if test -z `which xmlsectool`; then
  brew install xmlsectool
fi

xmlsectool \
  --sign \
  --inFile "$output"/dev/metadata.xml \
  --outFile "$output"/dev/metadata.signed.xml \
  --certificate "$certdir"/metadata_signing_a.crt \
  --key "$certdir"/metadata_signing_a.pk8 \
  --digest SHA-256
