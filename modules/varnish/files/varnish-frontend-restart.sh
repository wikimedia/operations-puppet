#!/bin/bash

set -e

# Depool cdn
confctl --quiet select name=`hostname -f`,service='cdn' set/pooled=no

# Wait a bit for the service to be drained
sleep 20

# Restart varnish-frontend
/usr/sbin/service varnish-frontend restart

sleep 15

# Repool cdn
confctl --quiet select name=`hostname -f`,service='cdn' set/pooled=yes
