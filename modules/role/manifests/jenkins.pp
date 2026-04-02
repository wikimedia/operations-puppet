# SPDX-License-Identifier: Apache-2.0
#
# role::jenkins
#
class role::jenkins {
    include profile::base::production
    include profile::firewall
    include profile::ci::jenkins
    include profile::ci::docker
    include profile::tlsproxy::envoy
}
