#!/bin/sh
HOSTNAME=$1

if [ -z $HOSTNAME ]
then
    echo Usage: ./gencrt [HOSTNAME]
    exit
else
    echo Generating Certificate...
fi

openssl req -new -nodes -newkey rsa:4096 \
  -keyout $HOSTNAME.key \
  -out $HOSTNAME.csr \
  -subj "/C=US/ST=State/L=City/O=Some-Organization-Name/CN=$HOSTNAME" &>/dev/null

cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
IP.1 = 192.168.77.252
IP.2 = $(host $HOSTNAME | awk '{ print $4 }')
IP.3 = 127.0.0.1
DNS.1 = localhost
DNS.2 = $HOSTNAME
DNS.3 = $HOSTNAME.unixmen.local
DNS.6 = app
# DNS.N = foo.bar
EOF

openssl x509 -req -sha512 -days 365 \
  -extfile v3.ext \
  -CA root.crt -CAkey root.key -CAcreateserial \
  -in $HOSTNAME.csr \
  -out $HOSTNAME.crt &>/dev/null

echo Sending Certificate to target...
scp $HOSTNAME.crt $HOSTNAME:$HOSTNAME.crt > /dev/null
scp $HOSTNAME.key $HOSTNAME:$HOSTNAME.key > /dev/null
rm $HOSTNAME.crt
rm $HOSTNAME.key
rm $HOSTNAME.csr
rm v3.ext

echo Done!
