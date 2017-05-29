class elasticsearch::curator (
    $hosts,
) {

    require_package('elasticsearch-curator')

    file { '/etc/curator/':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    elasticsearch::curator::config {
        'config':
            content => template('elasticsearch/curator/config.yaml.erb');
        'disable-shard-allocation.yaml':
            source => 'puppet:///modules/elasticsearch/curator/disable-shard-allocation.yaml';
        'enable-shard-allocation.yaml':
            source => 'puppet:///modules/elasticsearch/curator/enable-shard-allocation.yaml';
    }
}
