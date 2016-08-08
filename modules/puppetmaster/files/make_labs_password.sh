#!/bin/sh
alias errcho='>&2 echo'

INSTANCE=$1
DIRECTORY=/var/cache/instance-root-passwords

if [ -z "$INSTANCE" ]; then
    errcho "No instance name specified."
    exit 1
fi

if [ ! -d "$DIRECTORY" ]; then
    errcho "Directory for passwords not found."
    exit 1
fi

if [ -f $DIRECTORY/$INSTANCE ]; then
  PASSWORD=$(cat $DIRECTORY/$INSTANCE)
else
  PASSWORD=$(pwgen -sy -N 1)
  umask 027
  echo $PASSWORD > $DIRECTORY/$INSTANCE
fi
mkpasswd -m sha-512 $PASSWORD
