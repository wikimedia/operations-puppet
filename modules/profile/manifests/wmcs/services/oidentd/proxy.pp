# SPDX-License-Identifier: Apache-2.0
# Class: profile::wmcs::services::oidentd::proxy
#
# Provision an oident service acting as a proxy for NAT masqueraded clients.
#
class profile::wmcs::services::oidentd::proxy () {
    package { 'oidentd':
        ensure => absent,
    }
}
