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
    -nodes -config ./openssl-config.txt \
    -newkey rsa:2048 -set_serial 0 \
    -keyout ./example-private-key.txt \
    -out ./example-certificate.pem
popd
