#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#####################################################################
### THIS FILE IS MANAGED BY PUPPET
### puppet:///modules/base/environment/proxy.sh
#####################################################################
function set-proxy {
        export HTTP_PROXY=http://webproxy:8080
        export HTTPS_PROXY=http://webproxy:8080
        export http_proxy=http://webproxy:8080
        export https_proxy=http://webproxy:8080
        echo "Proxy set"
}
function unset-proxy {
        unset HTTP_PROXY
        unset HTTPS_PROXY
        unset http_proxy
        unset https_proxy
        echo "Proxy unset"
}