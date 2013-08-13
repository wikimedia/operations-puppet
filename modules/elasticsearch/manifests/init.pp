# = Class: elasticsearch
#
# This class installs/configures/manages the elasticsearch service.
#
# == Parameters:
# - $cluster_name:  name of the cluster for this elasticsearch instance to join
# - $heap_memory:   amount of memory to allocate to elasticsearch.  Defaults to
#       "2G".  Should be set to about half of ram or a 30G, whichever is
#       smaller.
# - $multicast_group:  multicast group to use for peer discovery.  Defaults to
#       elasticsearch's default: '224.2.2.4'.
#
# == Sample usage:
#
#   class { "elasticsearch":
#       cluster_name = 'labs-search'
#   }
#
class elasticsearch($cluster_name, $heap_memory = '2G',
    $multicast_group = '224.2.2.4') {
    # Install
    # Get a jdk on which to run elasticsearch
    java { 'java-default': }
    package { 'elasticsearch':
        ensure  => present,
        require => Java['java-default']
    }

    # Configure
    file { '/etc/elasticsearch/elasticsearch.yml':
        ensure  => present,
        content => template('elasticsearch/elasticsearch.yml.erb'),
        mode    => '0444',
        notify  => Service['elasticsearch'],
        require => Package['elasticsearch'],
    }
    file { '/etc/elasticsearch/logging.yml':
        ensure  => file,
        content => template('elasticsearch/logging.yml.erb'),
        mode    => '0444',
        notify  => Service['elasticsearch'],
        require => Package['elasticsearch'],
    }
    file { '/etc/default/elasticsearch':
        ensure  => file,
        content => template('elasticsearch/elasticsearch.erb'),
        mode    => '0444',
        notify  => Service['elasticsearch'],
        require => Package['elasticsearch'],
    }

    # Keep service running
    service { 'elasticsearch':
        ensure  => running,
        enable  => true,
        require => Package['elasticsearch'],
    }
}
