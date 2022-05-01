#!/bin/zsh

#  create-cert.zsh
#  EncryptCard
#
#  Created by Paul Zabelin on 4/30/22.
#  
pushd ${0:a:h}
which openssl
openssl version

openssl req -x509 \
    -config ./openssl-config.txt \
    -newkey rsa:2048 -set_serial 0 \
    -keyout ./example-private-key.txt \
    -out ./example-certificate.pem.txt

openssl x509 \
    -in ./example-certificate.pem.txt \
    -out ./example-certificate.cer \
    -outform der
    
encoded=$(base64 -i ./example-certificate.cer)
echo -n "***14340|$encoded***" > ./example-payment-gateway-key.txt

popd
