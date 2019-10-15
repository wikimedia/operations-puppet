#!/bin/bash

# https://kubernetes.io/docs/reference/generated/kube-proxy/
# kube-proxy does its own competing state dump and restore
# we stop kube-proxy here for the duration.
# Ferm seems to handle these pre-hooks intelligently in that
# a bad config or an unresolvable host in a rule is checked
# before any prehooks.  In that case Ferm itself will stop
# but kube-proxy will never be touched.
/usr/bin/logger -i -t ${0} "stop kube-proxy"
service kube-proxy stop
