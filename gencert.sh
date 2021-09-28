#!/bin/bash

# Signing certificate generation, inspired by
# https://gist.github.com/jonahb/7f247671efeada4fcf01

set -e

KIND=$1

usage() {
    echo "Usage: $0 <development|distribution>"
    exit 1
}

case "$KIND" in
    dev*)
        KIND=ios_development
        ;;
    dist*)
        KIND=ios_distribution
        ;;
    *)
        usage
        ;;
esac

workdir=$(mktemp -d cert.XXXXXX)
base="$workdir/signing"

. settings.dev

# Generate the key pair
openssl genrsa -out ${base}.key 2048

# Generate the certificate signing request (CSR). Apple ignores the subject, so we leave it blank:
openssl req -new -subj / -key ${base}.key -out ${base}.csr

# Call App Store Connect to create certificate, extract serial
serial=$(asc certificates create ios_development ${base}.csr --csv | tail +2 | cut -f1 -d',')

# Download the generated cert, in der format
asc certificates read $serial --certificate-output ${base}.crt

# Calculate the certificate identity
identity=`shasum -a 1 -b ${base}.crt | cut -f1 -d' '`

# Convert cert from der to pem
openssl x509 -inform der -in ${base}.crt -out ${base}.pem

# Package the key pair and certificate into a single PKCS #12 file. You’ll have to type an “export password.”
openssl pkcs12 -export -inkey ${base}.key -in ${base}.pem -out ${base}.p12

echo "Now, enter the export password in the import dialog"

# Import the signing certificate to make it available to code signing
security import ${base}.p12

echo "Successfully created and imported signing certificate with SHA-1 identity: $identity
Update SIGNING_IDENTITY in settings.env to use it for TIMOGRiOS.

PLEASE NOTE:
All generated files are left in '$workdir', should you need them for whatever.
Make sure NOT to add these to version control!
If you don't need them you can safely delete them,
your certificate lives in your keychain.
"
