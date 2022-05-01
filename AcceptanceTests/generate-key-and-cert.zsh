#!/bin/zsh

#  create-cert.zsh
#  EncryptCard
#
#  Created by Paul Zabelin on 4/30/22.
#  
here=${0:a:h}
which openssl
openssl version
openssl req -x509 \
    -nodes -config ${here}/openssl-config.txt \
    -newkey rsa:2048 -set_serial 0 \
    -keyout /tmp/example.key \
    -out /tmp/example.pem
