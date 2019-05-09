#!/bin/sh

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 hostname change_id"
    exit 1
fi

vagrant ssh -c "export JENKINS_USERNAME=$JENKINS_USERNAME ; export JENKINS_API_TOKEN=$JENKINS_API_TOKEN ; cd /vagrant/ ; ./run.py $1 $2 /utils/pcc"
