# = Class: elasticsearch
#
# This class decommissions the elasticsearch service.
#
class elasticsearch::decommission {
    # Remove package
    package { 'elasticsearch':
        ensure  => absent,
    }

    # Remove configuration
    file { '/etc/elasticsearch/elasticsearch.yml':
        ensure => absent,
    }
    file { '/etc/elasticsearch/logging.yml':
        ensure => absent,
    }
    file { '/etc/default/elasticsearch':
        ensure => absent,
    }
    file { '/etc/logrotate.d/elasticsearch':
        ensure => absent,
    }

    # Stop the service
    service { 'elasticsearch':
        ensure => stopped,
        enable => false,
    }
}
