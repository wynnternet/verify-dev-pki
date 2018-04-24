# Verify Dev-PKI

[![Build Status](https://travis-ci.org/alphagov/verify-dev-pki.svg?branch=master)](https://travis-ci.org/alphagov/verify-dev-pki)

This repo contains keys and certificates for use in integration tests.

The certificate chain matches the structure of that on production, but instead
of using BT trustwise as the root CA we just generate our own self signed certificate.

## Dependencies

We're using the [cfssl](https://github.com/cloudflare/cfssl) tool to generate all the
keys and certificates. This is written in `golang`, so you'll need that installed - https://golang.org/doc/install.

You'll also need to set the `$GOPATH` environment variable to some folder on your machine. Then simply run:

```
$ go get -u github.com/cloudflare/cfssl/cmd/cfssl
$ go get -u github.com/cloudflare/cfssl/cmd/cfssljson
```

to install cfssl.

## Generating Certs

Once you have cfssl installed you should be able to run `./scripts/generate-certs.sh` to recreate the certificates and keys.
These will be set to expire 100 years in the future, so you should only need to generate them when the PKI changes.

## Licence

[MIT Licence](LICENCE)

This code is provided for informational purposes only and is not yet intended for use outside GOV.UK Verify
