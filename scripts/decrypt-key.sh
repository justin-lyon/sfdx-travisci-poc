PASS=$1
INKEY=$2
OUTKEY=$3

openssl rsa -passin pass:$PASS -in $INKEY -out $OUTKEY
