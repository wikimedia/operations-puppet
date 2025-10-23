# SPDX-License-Identifier: Apache-2.0
# sets up a TCP proxy (using HAproxy)
class profile::tcpproxy {

    ensure_packages(['haproxy'])

    profile::auto_restarts::service { 'haproxy': }
}
