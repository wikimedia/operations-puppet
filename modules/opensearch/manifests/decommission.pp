# SPDX-License-Identifier: Apache-2.0
# = Class: opensearch
#
# This class decommissions the opensearch service.
#
class opensearch::decommission {
    # Remove package
    package { 'opensearch':
        ensure  => absent,
    }

    # Remove configuration
    file { '/etc/opensearch/opensearch.yml':
        ensure => absent,
    }
    file { '/etc/opensearch/logging.yml':
        ensure => absent,
    }
    file { '/etc/default/opensearch':
        ensure => absent,
    }
    logrotate::rule { 'opensearch':
        ensure => absent,
    }

    # Stop the service
    service { 'opensearch':
        ensure => stopped,
        enable => false,
    }
}
