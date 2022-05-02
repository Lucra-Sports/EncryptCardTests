#!/bin/zsh
#  generate-key-and-cert.zsh
#  EncryptCard
#
#  Created by Paul Zabelin on 4/30/22.
#
scriptDir=${0:a:h}
pushd ${scriptDir}/../EncryptCard/Tests

which openssl
openssl version

openssl req -x509 \
    -config ${scriptDir}/openssl-config.txt \
    -newkey rsa:2048 -set_serial 0 \
    -keyout ./example-private-key.txt \
    -out ./example-certificate.pem.txt
    
modulus1=$(openssl rsa -in ./example-private-key.txt -noout -modulus)
modulus2=$(openssl x509 -in ./example-certificate.pem.txt -noout -modulus)
if [[ $modulus1 != $modulus2 ]]
then
    echo "private and public key mismatch:"
    echo "private: $modulus1"
    echo "public: $modulus2"
    exit 1
fi

openssl x509 \
    -in ./example-certificate.pem.txt \
    -out ./example-certificate.cer \
    -outform der
    
encoded=$(base64 -i ./example-certificate.cer)
echo -n "***14340|$encoded***" > ./example-payment-gateway-key.txt

popd
