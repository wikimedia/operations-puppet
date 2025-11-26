# SPDX-License-Identifier: Apache-2.0
# Standalone Garage server host
class role::garage::server {
    include profile::base::production
    include profile::firewall
    include profile::tlsproxy::envoy
    include profile::garage
}
