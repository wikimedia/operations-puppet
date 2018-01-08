#!/bin/bash
# A guest user with a default 'guest' password will
# automatically be created for the RabbitMQ service.
# It should be never used

# recommendations seems to be to set to unknown
# value rather than remove the default account
# which may be handwaving based on older versions
# of rabbitmq not handling the missing builtin well
RNDM=$(date +%s | sha256sum | base64 | head -c 32 ; echo)
/usr/sbin/rabbitmqctl change_password guest $RNDM
/usr/sbin/rabbitmqctl list_users
