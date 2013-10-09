# = Class: elasticsearch
#
# This class installs/configures/manages the elasticsearch service.
#
# == Parameters:
# - $cluster_name:  name of the cluster for this elasticsearch instance to join
#       never name your cluster "elasticsearch" because that is the default
#       and you don't want servers without any configuration to join your
#       cluster.
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
class elasticsearch($cluster_name,
                    $heap_memory = '2G',
                    $multicast_group = '224.2.2.4',
                    $plugins_dir = '/usr/share/elasticsearch/plugins') {
    # Check arguments
    if $cluster_name == 'elasticsearch' {
        fail('$cluster_name must not be set to "elasticsearch"')
    }

    # Install
    # Get a jdk on which to run elasticsearch
    java { 'java-default': }
    package { 'elasticsearch':
        ensure  => present,
        require => [
            Java['java-default'],
            File['/etc/elasticsearch/elasticsearch.yml'],
            File['/etc/elasticsearch/logging.yml'],
            File['/etc/default/elasticsearch'],
        ]
    }

    # Configure
    file { '/etc/elasticsearch':
        ensure  => directory
    }
    file { '/etc/elasticsearch/elasticsearch.yml':
        ensure  => file,
        owner   => root,
        group   => root,
        content => template('elasticsearch/elasticsearch.yml.erb'),
        mode    => '0444',
        require => File['/etc/elasticsearch'],
    }
    file { '/etc/elasticsearch/logging.yml':
        ensure  => file,
        owner   => root,
        group   => root,
        content => template('elasticsearch/logging.yml.erb'),
        mode    => '0444',
        require => File['/etc/elasticsearch'],
    }
    file { '/etc/default/elasticsearch':
        ensure  => file,
        owner   => root,
        group   => root,
        content => template('elasticsearch/elasticsearch.erb'),
        mode    => '0444',
        require => File['/etc/elasticsearch'],
    }
    file { '/etc/logrotate.d/elasticsearch':
        ensure  => file,
        owner   => root,
        group   => root,
        mode    => '0444',
        source  => 'puppet:///modules/elasticsearch/logrotate',
    }
    # Note that we don't notify the Elasticsearch service of changes to its
    # config files because you need to be somewhat careful when restarting it.
    # So, for now at least, we'll be restarting it manually.

    # Keep service running
    service { 'elasticsearch':
        ensure  => running,
        enable  => true,
        require => Package['elasticsearch'],
    }

    # Make sure that some pesky, misleading log files aren't kept around
    # These files are created when the server is using the default cluster_name
    # and are never written to when the server is using the correct cluster name
    # thus leaving old files with no useful information named in such a way that
    # someone might think they contain useful logs.
    file { '/var/log/elasticsearch/elasticsearch.log':
        ensure => absent
    }
    file { '/var/log/elasticsearch/elasticsearch_index_indexing_slowlog.log':
        ensure => absent
    }
    file { '/var/log/elasticsearch/elasticsearch_index_search_slowlog.log':
        ensure => absent
    }
}
