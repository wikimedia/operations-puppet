# = Class: elasticsearch::curator
#
# This class installs elasticsearch-curator and all of the curator
# actions. Individual clusters to manage must be defined with
# elasticsearch::curator::cluster.
#
class elasticsearch::curator {
    apt::package_from_component { 'elasticsearch-curator':
        component => 'thirdparty/elasticsearch-curator5',
    }

    file { '/etc/curator/':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => true,
        purge   => true,
    }
    elasticsearch::curator::config {
        'disable-shard-allocation':
            source => 'puppet:///modules/elasticsearch/curator/disable-shard-allocation.yaml';
        'enable-shard-allocation':
            source => 'puppet:///modules/elasticsearch/curator/enable-shard-allocation.yaml';
    }
}

