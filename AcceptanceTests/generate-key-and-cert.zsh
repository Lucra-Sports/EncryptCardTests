#!/bin/zsh

#  create-cert.zsh
#  EncryptCard
#
#  Created by Paul Zabelin on 4/30/22.
#  

openssl req -x509 -nodes -config openssl-config.txt -newkey rsa:2048 -keyout /tmp/example.key -out /tmp/example.pem
