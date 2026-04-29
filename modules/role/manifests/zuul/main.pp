# SPDX-License-Identifier: Apache-2.0
# new zuul - main server (T393873)
class role::zuul::main {
    include profile::base::production
    include profile::firewall
    include profile::docker::engine
    include profile::docker::ferm
    include profile::zuul::base
    include profile::zuul::main
    include profile::zuul::webproxy
    include profile::zuul::zuul_web
    include profile::zuul::user
    include profile::zuul::nodepool
    include profile::zuul::launcher
    include profile::zuul::scheduler
    include profile::zookeeper::server
    include profile::tlsproxy::envoy
    include profile::pki::client
}
