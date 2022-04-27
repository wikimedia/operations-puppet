# = Class: opensearch::curator
#
# This class installs elasticsearch-curator and all of the curator
# actions. Individual clusters to manage must be defined with
# opensearch::curator::cluster.
#
class opensearch::curator {

    # TODO: use fork when available (T301017)
    package { 'elasticsearch-curator':
        ensure => '>=5.8.1'
    }

    file { '/etc/curator/':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => true,
        purge   => true,
    }
    opensearch::curator::config {
        'disable-shard-allocation':
            source => 'puppet:///modules/opensearch/curator/disable-shard-allocation.yaml';
        'enable-shard-allocation':
            source => 'puppet:///modules/opensearch/curator/enable-shard-allocation.yaml';
    }
}
