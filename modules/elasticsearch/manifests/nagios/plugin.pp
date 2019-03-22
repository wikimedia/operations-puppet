# == Class elasticsearch::nagios::plugin
# Includes the nagios checks for elasticsearch.
# include this class on your Nagios/Icinga node.
#
class elasticsearch::nagios::plugin {
    @file { '/usr/lib/nagios/plugins/check_elasticsearch':
      source => 'puppet:///modules/elasticsearch/nagios/check_elasticsearch',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      tag    => 'nagiosplugin',
    }

    # new version, can do more fine-grained checks
    @file { '/usr/lib/nagios/plugins/check_elasticsearch.py':
        source => 'puppet:///modules/elasticsearch/nagios/check_elasticsearch.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        tag    => 'nagiosplugin',
    }

    @file { '/usr/lib/nagios/plugins/check_cirrus_frozen_writes.py':
        source => 'puppet:///modules/elasticsearch/nagios/check_cirrus_frozen_writes.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        tag    => 'nagiosplugin',
    }

    @file { '/usr/lib/nagios/plugins/check_elasticsearch_shard_size.py':
        source => 'puppet:///modules/elasticsearch/nagios/check_elasticsearch_shard_size.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        tag    => 'nagiosplugin',
    }

    @file { '/usr/lib/nagios/plugins/check_elasticsearch_unassigned_shards.py':
        source => 'puppet:///modules/elasticsearch/nagios/check_elasticsearch_unassigned_shards.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        tag    => 'nagiosplugin',
    }

    require_package('python3-requests', 'python3-dateutil')
}
