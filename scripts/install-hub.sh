#!/usr/bin/env bash

HUB_REPO=${HUB_REPO:-"../ida-hub"}

./scripts/generate-certs.sh
./scripts/generate-truststores.sh
./scripts/generate-metadata.sh

cp -r stub-fed-config/* "$HUB_REPO"/stub-fed-config/
cp truststores/* "$HUB_REPO"/pki/
cp src/main/resources/dev-keys/hub_{signing,encryption}_{primary,secondary}.{crt,pk8} "$HUB_REPO"/pki/
cp src/main/resources/dev-keys/ocsp_responses "$HUB_REPO"/pki/
cp metadata/output/dev/metadata.signed.xml "$HUB_REPO"/metadata/metadata.xml
